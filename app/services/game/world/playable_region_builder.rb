# frozen_string_literal: true

module Game
  module World
    # Builds the soft-release 100×100 playable outdoor region: landmark cells,
    # resource nodes, fortress registry rows, and dungeon-floor NPC rings.
    # Idempotent. Preserves existing painted starter cell_art / source_map.
    class PlayableRegionBuilder
      CONFIG_PATH = Rails.root.join("config/gameplay/playable_region.yml")
      BATCH = 500

      Result = Struct.new(
        :cells_created, :cells_updated, :fortresses, :dungeon_npcs, :skipped,
        keyword_init: true
      )

      def initialize(config: nil)
        @config = (config || YAML.safe_load_file(CONFIG_PATH)).deep_stringify_keys
      end

      def call
        created = 0
        updated = 0
        skipped = 0

        # Do not materialize all 10_000 plain cells: sparse_default covers empty
        # outdoor terrain. Only landmark/resource/road overlays are persisted.
        landmark_rows.each do |row|
          outcome = upsert_landmark_cell!(row)
          case outcome
          when :created then created += 1
          when :updated then updated += 1
          else skipped += 1
          end
        end

        fort_count = sync_fortresses!
        dungeon_npcs = DungeonFloorPopulation.new(config: @config).call
        AshenAirshipStations.ensure!
        AshenGatherNodes.ensure!

        Result.new(
          cells_created: created,
          cells_updated: updated,
          fortresses: fort_count,
          dungeon_npcs: dungeon_npcs.placed + dungeon_npcs.updated,
          skipped:
        )
      end

      def self.config
        YAML.safe_load_file(CONFIG_PATH).deep_stringify_keys
      end

      def self.bounds
        cfg = config
        {
          zone: cfg.fetch("zone_name"),
          x0: cfg.fetch("origin_x").to_i,
          y0: cfg.fetch("origin_y").to_i,
          width: cfg.fetch("width").to_i,
          height: cfg.fetch("height").to_i
        }
      end

      private

      attr_reader :config

      def zone_name = config.fetch("zone_name")
      def seed_source = config.fetch("seed_source")
      def x0 = config.fetch("origin_x").to_i
      def y0 = config.fetch("origin_y").to_i
      def width = config.fetch("width").to_i
      def height = config.fetch("height").to_i

      def ensure_plain_grid!
        existing = MapTileTemplate.where(zone: zone_name)
          .where(x: x0...(x0 + width), y: y0...(y0 + height))
          .pluck(:x, :y)
          .to_set

        rows = []
        now = Time.current
        height.times do |dy|
          width.times do |dx|
            x = x0 + dx
            y = y0 + dy
            next if existing.include?([x, y])

            rows << {
              zone: zone_name,
              x:,
              y:,
              terrain_type: "outdoor",
              passable: true,
              metadata: {
                "seed_source" => seed_source,
                "sparse_generated" => true,
                "region" => "playable_100"
              },
              created_at: now,
              updated_at: now
            }
            if rows.size >= BATCH
              MapTileTemplate.insert_all(rows)
              rows = []
            end
          end
        end
        MapTileTemplate.insert_all(rows) if rows.any?
      end

      def landmark_rows
        rows = []
        Array(config["fortresses"]).each do |e|
          rows << landmark_from(e, "fortress")
          rows.concat(approach_ring(e.fetch("x").to_i, e.fetch("y").to_i, e.fetch("name"), "fortress"))
        end
        Array(config["castles"]).each do |e|
          rows << landmark_from(e, "castle")
          rows.concat(approach_ring(e.fetch("x").to_i, e.fetch("y").to_i, e.fetch("name"), "castle"))
        end
        Array(config["dungeons"]).each do |e|
          rows << dungeon_from(e)
          rows.concat(approach_ring(e.fetch("x").to_i, e.fetch("y").to_i, e.fetch("name"), "dungeon"))
        end
        Array(config["mines"]).each do |e|
          rows << mine_from(e)
          rows.concat(approach_ring(e.fetch("x").to_i, e.fetch("y").to_i, e.fetch("name"), "mine"))
        end
        Array(config["resource_nodes"]).each { |e| rows << resource_from(e) }
        Array(config["roads"]).each { |segment| rows.concat(road_cells(segment)) }
        rows
      end

      def approach_ring(cx, cy, name, kind)
        [[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [1, -1], [-1, 1], [1, 1]].filter_map do |dx, dy|
          x = cx + dx
          y = cy + dy
          next unless in_bounds?(x, y)

          {
            x:,
            y:,
            presence_label: "Подступ: #{name}",
            landmark: {
              "kind" => "approach",
              "key" => "approach_#{kind}_#{cx}_#{cy}_#{dx}_#{dy}",
              "name" => "Подступ к «#{name}»",
              "target_kind" => kind,
              "target_x" => cx,
              "target_y" => cy
            }
          }
        end
      end

      def in_bounds?(x, y)
        x.between?(x0, x0 + width - 1) && y.between?(y0, y0 + height - 1)
      end

      def landmark_from(entry, kind)
        {
          x: entry.fetch("x").to_i,
          y: entry.fetch("y").to_i,
          presence_label: entry.fetch("name"),
          landmark: {
            "kind" => kind,
            "key" => entry.fetch("key"),
            "name" => entry.fetch("name"),
            "siege" => kind == "fortress"
          }
        }
      end

      def dungeon_from(entry)
        {
          x: entry.fetch("x").to_i,
          y: entry.fetch("y").to_i,
          presence_label: entry.fetch("name"),
          landmark: {
            "kind" => "dungeon",
            "key" => entry.fetch("key"),
            "name" => entry.fetch("name"),
            "floors" => entry.fetch("floors", 3).to_i,
            "instance_id" => entry["instance_id"]
          }
        }
      end

      def mine_from(entry)
        {
          x: entry.fetch("x").to_i,
          y: entry.fetch("y").to_i,
          presence_label: entry.fetch("name"),
          landmark: {
            "kind" => "mine",
            "key" => entry.fetch("key"),
            "name" => entry.fetch("name")
          },
          resource_groups: [{
            "key" => entry.fetch("resource"),
            "kind" => "ore",
            "label" => entry.fetch("label"),
            "active" => true
          }],
          local_actions: [{
            "type" => "resource_search",
            "source_id" => "look",
            "label" => entry.fetch("label"),
            "active" => true
          }]
        }
      end

      def resource_from(entry)
        action_type = entry["type"].to_s == "fish" ? "fishing" : "resource_search"
        definition = MapTileTemplate.local_action_definition(action_type)
        {
          x: entry.fetch("x").to_i,
          y: entry.fetch("y").to_i,
          presence_label: entry.fetch("label"),
          landmark: {
            "kind" => "resource",
            "key" => entry.fetch("key"),
            "name" => entry.fetch("label")
          },
          resource_groups: [{
            "key" => entry.fetch("key"),
            "kind" => entry.fetch("type"),
            "label" => entry.fetch("label"),
            "active" => true
          }],
          local_actions: [{
            "type" => action_type,
            "source_id" => definition.fetch("source_id"),
            "label" => entry.fetch("label"),
            "active" => true
          }]
        }
      end

      def road_cells(segment)
        from = Array(segment["from"]).map(&:to_i)
        to = Array(segment["to"]).map(&:to_i)
        return [] if from.size != 2 || to.size != 2

        cells = []
        if from[0] == to[0]
          y_range = from[1] < to[1] ? (from[1]..to[1]) : (to[1]..from[1])
          y_range.each do |yy|
            next if yy == from[1] || yy == to[1]

            cells << road_cell(from[0], yy)
          end
        elsif from[1] == to[1]
          x_range = from[0] < to[0] ? (from[0]..to[0]) : (to[0]..from[0])
          x_range.each do |xx|
            next if xx == from[0] || xx == to[0]

            cells << road_cell(xx, from[1])
          end
        end
        cells
      end

      def road_cell(x, y)
        {
          x:, y:,
          presence_label: nil,
          landmark: {"kind" => "road", "key" => "road_#{x}_#{y}", "name" => "Дорога"},
          road: true
        }
      end

      def upsert_landmark_cell!(row)
        tile = MapTileTemplate.find_or_initialize_by(zone: zone_name, x: row[:x], y: row[:y])
        was_new = tile.new_record?
        meta = tile.metadata.to_h.deep_dup
        # Never strip painted starter art.
        meta["seed_source"] = seed_source
        meta["region"] = "playable_100"
        meta["landmark"] = row[:landmark] if row[:landmark]
        meta["presence_label"] = row[:presence_label] if row[:presence_label].present?
        meta["resource_groups"] = row[:resource_groups] if row[:resource_groups]
        meta["local_actions"] = row[:local_actions] if row[:local_actions]
        meta["road"] = true if row[:road]
        meta.delete("sparse_generated") if row[:landmark] && row[:landmark]["kind"] != "road"

        tile.assign_attributes(terrain_type: "outdoor", passable: true, metadata: meta)
        return :skipped unless tile.valid?

        tile.save!
        was_new ? :created : :updated
      end

      def sync_fortresses!
        count = 0
        (Array(config["fortresses"]) + Array(config["castles"])).each do |entry|
          record = WorldFortress.find_or_initialize_by(
            zone: zone_name,
            fortress_key: entry.fetch("key")
          )
          record.assign_attributes(
            x: entry.fetch("x").to_i,
            y: entry.fetch("y").to_i,
            name: entry.fetch("name"),
            kind: entry.fetch("kind", "fortress"),
            active: true,
            metadata: {
              "seed_source" => seed_source,
              "siege_enabled" => entry.fetch("kind", "fortress") == "fortress"
            }
          )
          record.save!
          count += 1
        end
        count
      end
    end
  end
end

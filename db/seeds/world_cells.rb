# frozen_string_literal: true

forpost_city_zones = Seeds::WorldContentSupport.city_zones

if defined?(MapTileTemplate)
  # Neverlands cities are node graphs, not grid maps. Remove obsolete city
  # tiles instead of retaining a parallel generic-town representation.
  city_zone_names = forpost_city_zones.map(&:name)
  MapTileTemplate.where(zone: city_zone_names).delete_all

  # Outpost Surroundings uses sparse authored overrides inside one logical
  # 1000x1000 region. Missing in-bounds rows use the deterministic passable
  # outdoor default shared by rendering and movement validation. cell_art stores
  # only a stable catalog key and zero-based sheet location; passability,
  # entrances, local actions, and hidden NPCs remain independent layers.
  outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
  outdoor_tiles = []
  if outpost_surroundings
    outdoor_zone_name = outpost_surroundings.name  # Store zone name as string, not the Zone object
    Game::World::CityCatalog::GATES.each_value do |gate|
      local_x, local_y = gate["local_coordinates"]
      outdoor_tiles << {
        zone: outdoor_zone_name,
        x: local_x,
        y: local_y,
        terrain_type: "outdoor",
        passable: true,
        metadata: {
          "city_gate" => gate["name"],
          "source_map" => gate["source_map"],
          "source_coordinates" => gate["source_coordinates"],
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => local_x.modulo(10),
            "row" => local_y.modulo(10)
          }
        }
      }
    end
    outdoor_tiles << {
      zone: outdoor_zone_name,
      x: 7,
      y: 7,
      terrain_type: "outdoor",
      passable: true,
      metadata: {
        "source_map" => "m_1001_999",
        "source_coordinates" => [1001, 999],
        "cell_art" => {
          "key" => "forpost_terrain",
          "column" => 7,
          "row" => 7
        },
        "local_actions" => [
          {
            "type" => "resource_search",
            "source_id" => "look",
            "label" => "Look Around",
            "description" => "Search this cell for herbs or local resources."
          }
        ]
      }
    }
    outdoor_tiles << {
      zone: outdoor_zone_name,
      x: 4,
      y: 6,
      terrain_type: "outdoor",
      passable: true,
      metadata: {
        "source_map" => "m_998_998",
        "source_coordinates" => [998, 998],
        "cell_art" => {
          "key" => "forpost_terrain",
          "column" => 4,
          "row" => 6
        }
      }
    }

    # Source [999,999] already carries the village-area label, but its cell
    # has no entrance. The authored TileBuilding at [4,6] alone supplies Enter.
    outdoor_tiles << {
      zone: outdoor_zone_name, x: 5, y: 7, terrain_type: "outdoor", passable: true,
      metadata: {
        "source_map" => "m_999_999", "source_coordinates" => [999, 999],
        "source_observation" => "2026-09-09_starter_routes",
        "presence_label" => "Frontier Village"
      }
    }

    # September 8 live pond: source [1007,1002], reached from the eastern
    # gate. Drinking is captured; fishing's successful profession loop remains
    # deferred. Cell art and action eligibility are independent authored data.
    existing_pond = MapTileTemplate.find_by(zone: outdoor_zone_name, x: 13, y: 10)
    outdoor_tiles << {
      zone: outdoor_zone_name,
      x: 13,
      y: 10,
      terrain_type: "outdoor",
      passable: existing_pond ? existing_pond.passable : true,
      metadata: {
        "source_map" => "m_1007_1002",
        "source_coordinates" => [1007, 1002],
        "source_observation" => "2026-09-08_cell_content_and_world_rules",
        "presence_label" => "Outpost Surroundings, Pond",
        "cell_art" => {"key" => "forpost_pond", "column" => 2, "row" => 2},
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "label" => "Look Around", "active" => true,
           "result_message" => "Nothing found."},
          {"type" => "drinking", "source_id" => "dri", "label" => "Drink", "active" => true},
          {"type" => "fishing", "source_id" => "fis", "label" => "Fish", "active" => true}
        ]
      }.merge(existing_pond&.metadata.to_h || {})
    }

    # Live eastern intermediate [1006,1002]: Look is available here, with
    # the captured 28-second empty-vegetation result; water actions are absent.
    outdoor_tiles << {
      zone: outdoor_zone_name, x: 12, y: 10, terrain_type: "outdoor", passable: true,
      metadata: {
        "source_map" => "m_1006_1002",
        "source_coordinates" => [1006, 1002],
        "source_observation" => "2026-09-09_starter_routes",
        "local_actions" => [{"type" => "resource_search", "source_id" => "look", "label" => "Look Around"}]
      }
    }

  end

  outdoor_tiles.each do |attrs|
    next unless attrs[:zone]
    tile = MapTileTemplate.find_or_initialize_by(zone: attrs[:zone], x: attrs[:x], y: attrs[:y])
    source_map = tile.metadata.to_h["source_map"]
    next if tile.persisted? && source_map.present? &&
      !source_map.match?(/\Am_\d+_\d+\z/) && source_map != "forpost_pond_neighborhood_art"

    tile.terrain_type = attrs[:terrain_type]
    tile.passable = attrs.fetch(:passable, true) if tile.new_record?
    tile.metadata = attrs.fetch(:metadata, {}).merge(tile.metadata.to_h)
    tile.save!
  end

  # Bootstrap the bounded atlas survey into the same editable cell records.
  # Existing atlas-backed rows are operator-owned after import; reseeding must
  # not reopen a disabled cell or replace its managed actions/resources. Legacy
  # source/default-art rows receive the first survey, while unrelated authored
  # rows remain untouched. No NPC roster or successful yield is inferred here.
  if outpost_surroundings
    starter_catalog = Game::World::StarterCellCatalog.default
    starter_catalog.cells.each do |cell|
      tile = MapTileTemplate.find_or_initialize_by(zone: starter_catalog.zone_name, x: cell.x, y: cell.y)
      next if tile.metadata.to_h.key?("atlas")

      source_map = tile.metadata.to_h["source_map"]
      next if tile.persisted? && source_map.present? &&
        !source_map.match?(/\Am_\d+_\d+\z/) && source_map != "forpost_pond_neighborhood_art"

      tile.terrain_type = "outdoor"
      tile.passable = cell.passable
      tile.metadata = cell.metadata.merge(tile.metadata.to_h).merge(
        "source_map" => cell.metadata.fetch("source_map"),
        "source_coordinates" => cell.metadata.fetch("source_coordinates")
      )
      tile.metadata["resource_groups"] ||= cell.metadata.dig("atlas", "herb_groups").map do |group|
        {"key" => "herbs_#{group}", "kind" => "herbs", "label" => "Herb group #{group}", "active" => true}
      end
      tile.save!
    end
  end

  # One continuous 21x13 landscape replaces legacy terrain/pond art throughout
  # the bounded starter survey. Art coordinates are relative to local [0,2].
  # Existing independent artwork and already-managed starter references survive;
  # this visual upgrade never changes gameplay, labels or saved positions.
  if outpost_surroundings
    MapTileTemplate.where(zone: starter_catalog.zone_name, x: 0..20, y: 2..14).find_each do |tile|
      reference = tile.metadata.to_h["cell_art"]
      next unless reference.blank? || %w[forpost_terrain forpost_pond].include?(reference["key"])

      tile.update!(metadata: tile.metadata.to_h.merge(
        "cell_art" => {"key" => "forpost_starter", "column" => tile.x, "row" => tile.y - 2}
      ))
    end
  end

  if outpost_surroundings
    current_gate_cells = Game::World::CityCatalog::GATES.values.map { |gate| gate["local_coordinates"] }
    MapTileTemplate.where(zone: outpost_surroundings.name).find_each do |authored_tile|
      next unless authored_tile.metadata.to_h["city_gate"].present?
      next if current_gate_cells.include?([authored_tile.x, authored_tile.y])

      if starter_catalog.at(authored_tile.x, authored_tile.y)
        # Keep the surveyed cell: deleting it would restore sparse passable
        # terrain for a blocked coordinate until the next seed invocation.
        authored_tile.update!(metadata: authored_tile.metadata.except("city_gate"))
      else
        authored_tile.destroy!
      end
    end
  end
end

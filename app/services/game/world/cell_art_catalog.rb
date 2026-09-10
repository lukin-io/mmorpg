# frozen_string_literal: true

module Game
  module World
    # Resolves stable, source-backed cell-art keys to project-owned asset-sheet
    # crops or individual cell PNGs. Runtime records provide only a key and
    # zero-based column/row;
    # asset paths, fixed cell dimensions, and sheet bounds remain server-owned.
    # Configuration is cached for the process lifetime and can be explicitly
    # reloaded by development tooling or isolated specs.
    class CellArtCatalog
      CONFIG_PATH = Rails.root.join("config/gameplay/world_cell_art.yml")
      CELL_SIZE = 100
      LEGACY_STARTER_KEYS = %w[forpost_terrain forpost_pond].freeze

      Presentation = Data.define(
        :key,
        :asset,
        :high_density_asset,
        :column,
        :row,
        :cell_width,
        :cell_height,
        :sheet_width,
        :sheet_height,
        :physical_slice,
        :landmarks_in_art,
        :painted_building_key
      ) do
        def background_x
          physical_slice ? 0 : -(column * cell_width)
        end

        def background_y
          physical_slice ? 0 : -(row * cell_height)
        end

        # The caller supplies the actual projected TileBuilding key, not a
        # key copied from editable cell metadata. A blanket art flag is never
        # enough to hide a moved or newly authored entrance.
        def painted_building?(building_key)
          landmarks_in_art && painted_building_key.present? && painted_building_key == building_key
        end
      end

      class << self
        # Returns the normalized YAML catalog keyed by stable persisted identity.
        # Reading it has no gameplay side effects, but the result is memoized.
        def config
          @config ||= YAML.safe_load_file(CONFIG_PATH).to_h.deep_stringify_keys
        end

        # Clears and returns the cached catalog. Use after changing YAML in a
        # running development process or when a spec temporarily replaces it.
        def reload!
          @config = nil
          config
        end

        # Accepts hash-like tile metadata with key and optional column/row.
        # Returns a validated Presentation for rendering, or nil when the entry,
        # asset, dimensions, or requested sheet coordinate is invalid. A catalog
        # declaring physical slices requires that exact PNG; its authoring
        # master is never a runtime substitute for a missing cell. An optional
        # 2x physical PNG enhances that same cell while retaining 100px geometry
        # and its mandatory 1x fallback; it cannot replace a missing base PNG.
        def resolve(reference)
          attributes = normalize_reference(reference)
          return unless attributes

          definition = normalized_definition(attributes["key"])
          return unless definition

          column = integer(attributes.fetch("column", 0))
          row = integer(attributes.fetch("row", 0))
          return unless column&.between?(0, definition.fetch("columns") - 1)
          return unless row&.between?(0, definition.fetch("rows") - 1)

          slice = slice_asset(definition["slices_directory"], column, row)
          return if definition["slices_directory"] && slice.nil?
          landmark = definition.fetch("painted_landmarks").find do |entry|
            entry["column"] == column && entry["row"] == row
          end
          Presentation.new(
            key: attributes["key"],
            asset: slice || definition.fetch("asset"),
            high_density_asset: slice && slice_asset(definition["high_density_slices_directory"], column, row),
            column:,
            row:,
            cell_width: definition.fetch("cell_width"),
            cell_height: definition.fetch("cell_height"),
            sheet_width: slice ? CELL_SIZE : definition.fetch("columns") * CELL_SIZE,
            sheet_height: slice ? CELL_SIZE : definition.fetch("rows") * CELL_SIZE,
            physical_slice: slice.present?,
            landmarks_in_art: definition.fetch("landmarks_in_art"),
            painted_building_key: landmark&.fetch("building_key")
          )
        end

        # Returns whether hash-like tile metadata resolves to safe catalog art.
        def valid_reference?(reference)
          resolve(reference).present?
        end

        # Render the complete existing starter landscape even when gameplay
        # records were imported only for a bounded route. This coordinate
        # default is presentation-only and performs no database work. Valid
        # independent or edited starter references win; malformed explicit
        # references retain resolve's nil result and the renderer's recovery.
        # The surveyed western margin illustrates otherwise inert outside-zone
        # buffer cells; it does not extend gameplay coordinates or content.
        def resolve_for_tile(reference, zone:, x:, y:)
          explicit = resolve(reference)
          return explicit unless starter_region?(zone)
          return explicit unless x.is_a?(Integer) && y.is_a?(Integer) && x.between?(-3, 20) && y.between?(2, 14)
          return explicit if reference.present? && explicit.nil?
          return explicit if explicit && (x.negative? || !LEGACY_STARTER_KEYS.include?(explicit.key))

          key, column = x.negative? ? ["forpost_starter_west", x + 3] : ["forpost_starter", x]
          resolve("key" => key, "column" => column, "row" => y - 2)
        end

        private

        def starter_region?(zone)
          zone&.outdoor? && zone.name == "Outpost Surroundings" && zone.width == 1000 && zone.height == 1000 &&
            zone.metadata.to_h["source_map"] == "m_1001_999"
        end

        def normalize_reference(reference)
          return unless reference.respond_to?(:to_h)

          attributes = reference.to_h.deep_stringify_keys
          attributes if attributes["key"].present?
        rescue ArgumentError, TypeError
          nil
        end

        def normalized_definition(key)
          definition = config[key.to_s]
          return unless definition.respond_to?(:to_h)

          attributes = definition.to_h.deep_stringify_keys
          asset = attributes["asset"].to_s
          cell_width = integer(attributes["cell_width"])
          cell_height = integer(attributes["cell_height"])
          columns = integer(attributes["columns"])
          rows = integer(attributes["rows"])
          source_reference = attributes["source_reference"].to_s
          return unless safe_asset?(asset)
          if attributes.key?("slices_directory")
            return unless safe_directory?(attributes["slices_directory"])
          end
          if attributes.key?("high_density_slices_directory")
            return unless attributes["slices_directory"] && safe_directory?(attributes["high_density_slices_directory"])
          end
          landmarks_in_art = attributes.fetch("landmarks_in_art", false)
          return unless [true, false].include?(landmarks_in_art)
          return unless cell_width == CELL_SIZE && cell_height == CELL_SIZE
          return unless columns&.positive? && rows&.positive?
          landmarks = attributes.fetch("painted_landmarks", [])
          return unless valid_landmarks?(landmarks, columns, rows)
          return if source_reference.blank?
          return unless attributes["slices_directory"] || asset_exists?(asset)

          attributes.merge(
            "asset" => asset,
            "cell_width" => cell_width,
            "cell_height" => cell_height,
            "columns" => columns,
            "rows" => rows,
            "landmarks_in_art" => landmarks_in_art,
            "painted_landmarks" => landmarks
          )
        rescue ArgumentError, TypeError
          nil
        end

        def safe_asset?(asset)
          asset.match?(%r{\Aworld/(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+\.(?:png|jpe?g|webp|gif)\z})
        end

        def valid_landmarks?(landmarks, columns, rows)
          return false unless landmarks.is_a?(Array)

          valid = landmarks.all? do |entry|
            entry.is_a?(Hash) && entry.keys.sort == %w[building_key column row] &&
              entry["column"].is_a?(Integer) && entry["column"].between?(0, columns - 1) &&
              entry["row"].is_a?(Integer) && entry["row"].between?(0, rows - 1) &&
              entry["building_key"].is_a?(String) && entry["building_key"].match?(/\A[a-z0-9][a-z0-9_-]*\z/)
          end
          valid && landmarks.map { |entry| entry.values_at("column", "row") }.uniq.size == landmarks.size &&
            landmarks.pluck("building_key").uniq.size == landmarks.size
        end

        def safe_directory?(directory)
          directory.is_a?(String) && directory.match?(%r{\Aworld(?:/[a-zA-Z0-9_-]+)+\z})
        end

        # The catalog owns the directory and file naming. A missing individual
        # PNG fails closed instead of loading the authoring master.
        def slice_asset(directory, column, row)
          return unless directory

          asset = "#{directory}/#{column}_#{row}.png"
          asset if asset_exists?(asset)
        end

        def asset_exists?(asset)
          Rails.root.join("app/assets/images", asset).file?
        end

        def integer(value)
          Integer(value.to_s, exception: false)
        end
      end
    end
  end
end

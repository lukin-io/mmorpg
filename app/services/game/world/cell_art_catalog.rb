# frozen_string_literal: true

module Game
  module World
    # Resolves stable, source-backed cell-art keys to project-owned asset-sheet
    # slices. Runtime records provide only a key and zero-based column/row;
    # asset paths, fixed cell dimensions, and sheet bounds remain server-owned.
    # Configuration is cached for the process lifetime and can be explicitly
    # reloaded by development tooling or isolated specs.
    class CellArtCatalog
      CONFIG_PATH = Rails.root.join("config/gameplay/world_cell_art.yml")
      CELL_SIZE = 100

      Presentation = Data.define(
        :key,
        :asset,
        :column,
        :row,
        :cell_width,
        :cell_height,
        :sheet_width,
        :sheet_height
      ) do
        def background_x
          -(column * cell_width)
        end

        def background_y
          -(row * cell_height)
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
        # asset, dimensions, or requested sheet coordinate is invalid.
        def resolve(reference)
          attributes = normalize_reference(reference)
          return unless attributes

          definition = normalized_definition(attributes["key"])
          return unless definition

          column = integer(attributes.fetch("column", 0))
          row = integer(attributes.fetch("row", 0))
          return unless column&.between?(0, definition.fetch("columns") - 1)
          return unless row&.between?(0, definition.fetch("rows") - 1)

          Presentation.new(
            key: attributes["key"],
            asset: definition.fetch("asset"),
            column:,
            row:,
            cell_width: definition.fetch("cell_width"),
            cell_height: definition.fetch("cell_height"),
            sheet_width: definition.fetch("columns") * definition.fetch("cell_width"),
            sheet_height: definition.fetch("rows") * definition.fetch("cell_height")
          )
        end

        # Returns whether hash-like tile metadata resolves to safe catalog art.
        def valid_reference?(reference)
          resolve(reference).present?
        end

        private

        def normalize_reference(reference)
          return unless reference.respond_to?(:to_h)

          attributes = reference.to_h.deep_stringify_keys
          attributes if attributes["key"].present?
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
          return unless cell_width == CELL_SIZE && cell_height == CELL_SIZE
          return unless columns&.positive? && rows&.positive?
          return if source_reference.blank?
          return unless Rails.root.join("app/assets/images", asset).file?

          attributes.merge(
            "asset" => asset,
            "cell_width" => cell_width,
            "cell_height" => cell_height,
            "columns" => columns,
            "rows" => rows
          )
        end

        def safe_asset?(asset)
          asset.start_with?("world/") && !asset.include?("..")
        end

        def integer(value)
          Integer(value, exception: false)
        end
      end
    end
  end
end

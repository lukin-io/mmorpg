# frozen_string_literal: true

require "ostruct"

module Game
  module World
    # Projects the native-cell walking buffer, optionally sending just its new
    # edges. The signed client token is a presentation hint, never a position or
    # movement capability. Viewport hints select a bounded odd-cell window;
    # one off-screen cell on every edge keeps travel continuous.
    # Changed/deleted authored content invalidates reuse; reload always works
    # without a token. No cache, per-client server state, or region scan is used.
    class MapBuffer
      DEFAULT_COLUMNS = 3
      DEFAULT_ROWS = 5
      MAX_COLUMNS = 39
      MAX_ROWS = 9
      Result = Data.define(:rows, :token, :base_token, :revision, :visible_columns, :visible_rows) do
        def width = visible_columns + 2
        def height = visible_rows + 2
      end

      def initialize(position:, token: nil, columns: nil, rows: nil, verifier: Rails.application.message_verifier("world-map-buffer"))
        @position = position
        @token = token
        @verifier = verifier
        @visible_columns = dimension(columns, default: DEFAULT_COLUMNS, maximum: MAX_COLUMNS)
        @visible_rows = dimension(rows, default: DEFAULT_ROWS, maximum: MAX_ROWS)
      end

      # Returns full rows or entering edge cells, plus the next signed buffer
      # identity and validated visible dimensions. Tokens are scoped to the
      # character, region and viewport and expire after 30 minutes. A resize or
      # malformed hint recovers with a full bounded snapshot, never a region read.
      def call
        previous = previous_buffer
        load_content(previous)
        reusable = reusable_buffer?(previous)
        revision = (Time.current.to_r * 1_000_000).to_i
        next_token = generate_token
        rows = build_rows(reusable ? previous : nil)

        Result.new(rows:, token: next_token, base_token: reusable ? token : nil, revision:, visible_columns:, visible_rows:)
      end

      private

      attr_reader :position, :token, :verifier, :templates, :buildings, :visible_columns, :visible_rows

      def dimension(value, default:, maximum:)
        number = Integer(value.to_s, exception: false)
        number&.between?(3, maximum) && number.odd? ? number : default
      end

      def x_radius = visible_columns / 2 + 1
      def y_radius = visible_rows / 2 + 1

      def zone
        position.zone
      end

      def previous_buffer
        return unless token.is_a?(String) && token.bytesize <= 2048

        data = verifier.verified(token)
        return unless data.is_a?(Hash) && data["character_id"] == position.character_id && data["zone_id"] == zone.id
        return unless data["columns"] == visible_columns && data["rows"] == visible_rows
        return unless data["x"].is_a?(Integer) && data["y"].is_a?(Integer)
        return unless (data["x"] - position.x).abs <= 1 && (data["y"] - position.y).abs <= 1

        data
      end

      def load_content(previous)
        old_x, old_y = previous ? previous.values_at("x", "y") : [position.x, position.y]
        x_range = ([old_x, position.x].min - x_radius)..([old_x, position.x].max + x_radius)
        y_range = ([old_y, position.y].min - y_radius)..([old_y, position.y].max + y_radius)
        @templates = MapTileTemplate.in_zone(zone.name).in_area(x_range, y_range).index_by { |tile| [tile.x, tile.y] }
        @buildings = TileBuilding.active.in_zone(zone.name).where(x: x_range, y: y_range).index_by { |building| [building.x, building.y] }
      end

      def reusable_buffer?(previous)
        previous && previous["fingerprint"] == fingerprint(previous["x"], previous["y"])
      end

      def generate_token
        verifier.generate({
          "character_id" => position.character_id, "zone_id" => zone.id,
          "columns" => visible_columns, "rows" => visible_rows,
          "x" => position.x, "y" => position.y,
          "fingerprint" => fingerprint(position.x, position.y)
        }, expires_in: 30.minutes)
      end

      def build_rows(reused_buffer)
        ((position.y - y_radius)..(position.y + y_radius)).map do |y|
          ((position.x - x_radius)..(position.x + x_radius)).filter_map do |x|
            next if reused_buffer && within_buffer?(x, y, reused_buffer["x"], reused_buffer["y"])

            tile_at(x, y)
          end
        end
      end

      def within_buffer?(x, y, center_x, center_y)
        x.between?(center_x - x_radius, center_x + x_radius) && y.between?(center_y - y_radius, center_y + y_radius)
      end

      def fingerprint(center_x, center_y)
        records = [templates, buildings].map do |layer|
          layer.filter_map do |(x, y), record|
            next unless within_buffer?(x, y, center_x, center_y)

            # Content edits, activation changes, movement, and deletion must not
            # leave an old visible cell behind. Persisted attributes also catch
            # maintenance updates that deliberately skip updated_at callbacks.
            [x, y, record.attributes]
          end.sort_by { |x, y, _| [y, x] }
        end
        Digest::SHA256.hexdigest(ActiveSupport::JSON.encode([zone.attributes, records]))
      end

      def tile_at(x, y)
        in_bounds = x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)
        template = templates[[x, y]] if in_bounds
        building = buildings[[x, y]] if in_bounds
        metadata = if template
          template.metadata.to_h.deep_dup
        elsif in_bounds
          {"sparse_default" => true}
        else
          {"out_of_bounds" => true}
        end
        if building
          metadata["building"] = building.name
          metadata["building_kind"] = building.location? ? building.location_kind : building.building_type
        end
        OpenStruct.new(
          x:, y:, terrain_type: template&.terrain_type || zone.location_type,
          building_key: building&.building_key,
          walkable: in_bounds && (template ? template.walkable : zone.outdoor?),
          passable: in_bounds && (template ? template.passable : zone.outdoor?), metadata:
        )
      end
    end
  end
end

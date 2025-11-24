# frozen_string_literal: true

module Game
  module Movement
    # TileProvider caches map tile metadata for a zone and exposes tile_at lookups.
    #
    # Usage:
    #   provider = Game::Movement::TileProvider.new(zone:)
    #   provider.tile_at(0, 1)
    class TileProvider
      def initialize(zone:)
        @zone = zone
        @tiles = build_tile_index
      end

      def tile_at(x, y)
        record = tiles[[x, y]]
        return unless record

        Game::Maps::Tile.new(x:, y:, passable: record.passable)
      end

      def biome_at(x, y)
        tiles[[x, y]]&.biome || zone.biome
      end

      def metadata_at(x, y)
        tiles[[x, y]]&.metadata || {}
      end

      def terrain_type_at(x, y)
        tiles[[x, y]]&.terrain_type
      end

      private

      attr_reader :zone, :tiles

      def build_tile_index
        MapTileTemplate.where(zone: zone.name).index_by { |tile| [tile.x, tile.y] }
      end
    end
  end
end

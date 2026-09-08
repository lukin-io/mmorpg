# frozen_string_literal: true

module Game
  module Movement
    # Reads authored movement cells inside one zone without loading the region.
    # Optional coordinates are prefetched in one exact-cell query; other cells
    # are read once on demand. Missing authored rows are memoized too. This
    # request-local snapshot returns passability, metadata, or terrain through
    # the public lookups and performs no writes.
    #
    # Usage:
    #   provider = Game::Movement::TileProvider.new(zone:)
    #   provider.tile_at(0, 1)
    class TileProvider
      def initialize(zone:, coordinates: [])
        @zone = zone
        @tiles = {}
        preload_tiles(coordinates)
      end

      def tile_at(x, y)
        # Check bounds first
        return nil unless in_bounds?(x, y)

        record = record_at(x, y)

        if record
          Game::Maps::Tile.new(x:, y:, passable: record.passable)
        else
          Game::Maps::Tile.new(x:, y:, passable: true)
        end
      end

      def metadata_at(x, y)
        record_at(x, y)&.metadata || {}
      end

      def terrain_type_at(x, y)
        record_at(x, y)&.terrain_type
      end

      private

      attr_reader :zone, :tiles

      def record_at(x, y)
        return nil unless in_bounds?(x, y)

        coordinates = [x, y]
        return tiles[coordinates] if tiles.key?(coordinates)

        tiles[coordinates] = MapTileTemplate.find_by(zone: zone.name, x:, y:)
      end

      def preload_tiles(coordinates)
        coordinates.each do |x, y|
          tiles[[x, y]] = nil if in_bounds?(x, y)
        end
        return if tiles.empty?

        MapTileTemplate.where(zone: zone.name).where([:x, :y] => tiles.keys).each do |tile|
          tiles[[tile.x, tile.y]] = tile
        end
      end

      def in_bounds?(x, y)
        x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)
      end
    end
  end
end

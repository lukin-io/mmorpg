# frozen_string_literal: true

module Game
  module Maps
    class Grid
      attr_reader :width, :height, :tiles

      def initialize(width:, height:)
        @width = width
        @height = height
        @tiles = Array.new(height) { Array.new(width) }
      end

      def set_tile(x, y, tile)
        tiles.fetch(y)[x] = tile
      end

      def tile_at(x, y)
        return nil unless x.between?(0, width - 1)
        return nil unless y.between?(0, height - 1)

        tiles[y][x]
      end
    end
  end
end

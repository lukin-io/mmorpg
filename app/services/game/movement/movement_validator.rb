# frozen_string_literal: true

module Game
  module Movement
    class MovementValidator
      def initialize(grid)
        @grid = grid
      end

      def valid?(x, y)
        tile = grid.tile_at(x, y)
        tile&.passable?
      end

      private

      attr_reader :grid
    end
  end
end

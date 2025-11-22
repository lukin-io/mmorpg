# frozen_string_literal: true

module Game
  module Movement
    class MovementValidator
      def initialize(tile_source)
        @tile_source = tile_source
      end

      def valid?(x, y)
        tile = tile_source.tile_at(x, y)
        tile&.passable?
      end

      private

      attr_reader :tile_source
    end
  end
end

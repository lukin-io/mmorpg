# frozen_string_literal: true

module Game
  module Maps
    class Tile
      attr_reader :x, :y, :passable

      def initialize(x:, y:, passable: true)
        @x = x
        @y = y
        @passable = passable
      end

      def passable?
        passable
      end
    end
  end
end

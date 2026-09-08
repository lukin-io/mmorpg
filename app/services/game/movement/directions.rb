# frozen_string_literal: true

module Game
  module Movement
    module Directions
      OFFSETS = {
        north: [0, -1],
        south: [0, 1],
        east: [1, 0],
        west: [-1, 0],
        northeast: [1, -1],
        southeast: [1, 1],
        southwest: [-1, 1],
        northwest: [-1, -1]
      }.freeze

      module_function

      def adjacent?(from_x:, from_y:, target_x:, target_y:)
        coordinates = [from_x, from_y, target_x, target_y]
        return false unless coordinates.all?(Integer)

        delta_x = (target_x - from_x).abs
        delta_y = (target_y - from_y).abs

        delta_x <= 1 && delta_y <= 1 && (delta_x.positive? || delta_y.positive?)
      end

      def matches?(direction:, from_x:, from_y:, target_x:, target_y:)
        return false unless adjacent?(from_x:, from_y:, target_x:, target_y:)

        OFFSETS[direction.to_s.to_sym] == [target_x - from_x, target_y - from_y]
      end
    end
  end
end

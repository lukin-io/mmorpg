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
    end
  end
end

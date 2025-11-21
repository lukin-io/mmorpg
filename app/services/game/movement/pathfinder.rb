# frozen_string_literal: true

module Game
  module Movement
    class Pathfinder
      DIRECTIONS = [ [ 1, 0 ], [ -1, 0 ], [ 0, 1 ], [ 0, -1 ] ].freeze

      def initialize(grid, validator: MovementValidator)
        @grid = grid
        @validator = validator.new(grid)
      end

      def shortest_path(start:, goal:)
        queue = [ [ start, [ start ] ] ]
        visited = { start => true }

        until queue.empty?
          (current, path) = queue.shift
          return path if current == goal

          DIRECTIONS.each do |dx, dy|
            next_coordinate = [ current[0] + dx, current[1] + dy ]
            next if visited[next_coordinate]
            next unless validator.valid?(*next_coordinate)

            visited[next_coordinate] = true
            queue << [ next_coordinate, path + [ next_coordinate ] ]
          end
        end

        []
      end

      private

      attr_reader :grid, :validator
    end
  end
end

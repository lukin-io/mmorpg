# frozen_string_literal: true

module Arena
  module TacticalCombat
    # Calculates valid movement positions for a character.
    class MoveCalculator
      attr_reader :match, :character

      def initialize(match:, character:)
        @match = match
        @character = character
      end

      # Returns array of {x:, y:} positions that are valid moves
      def valid_positions
        participant = match.tactical_participants.find_by(character: character)
        return [] unless participant

        positions = []
        range = participant.movement_range

        (-range..range).each do |dx|
          (-range..range).each do |dy|
            next if dx == 0 && dy == 0
            next if dx.abs + dy.abs > range # Manhattan distance

            new_x = participant.grid_x + dx
            new_y = participant.grid_y + dy

            next unless valid_position?(new_x, new_y)

            positions << {x: new_x, y: new_y, distance: dx.abs + dy.abs}
          end
        end

        positions.sort_by { |p| p[:distance] }
      end

      # Returns array of characters that can be attacked
      def valid_targets
        participant = match.tactical_participants.find_by(character: character)
        return [] unless participant

        match.tactical_participants.alive.reject { |p| p.character == character }.select do |target|
          participant.can_attack?(target)
        end.map(&:character)
      end

      private

      def valid_position?(x, y)
        return false if x.negative? || y.negative?
        return false if x >= match.grid_size || y >= match.grid_size
        return false if match.tile_occupied?(x, y)

        tile = match.grid_state&.dig(y, x)
        return true if tile.nil?
        return true unless tile.is_a?(Hash)

        tile.fetch("passable", true)
      end
    end
  end
end

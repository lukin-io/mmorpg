# frozen_string_literal: true

module Arena
  module TacticalCombat
    # Processes movement actions in tactical combat.
    class MoveProcessor
      attr_reader :match, :character, :target_x, :target_y

      def initialize(match:, character:, target_x:, target_y:)
        @match = match
        @character = character
        @target_x = target_x
        @target_y = target_y
      end

      def execute!
        return {success: false, error: "Match is not active"} unless match.active?
        return {success: false, error: "Position out of bounds"} unless valid_bounds?
        return {success: false, error: "Tile is occupied"} if match.tile_occupied?(target_x, target_y)
        return {success: false, error: "Tile is impassable"} if impassable_tile?

        participant = match.tactical_participants.find_by(character: character)
        return {success: false, error: "Participant not found"} unless participant
        return {success: false, error: "Out of movement range"} unless in_range?(participant)

        if match.move_character!(character, target_x, target_y)
          log_movement!(participant)
          {success: true, new_position: {x: target_x, y: target_y}}
        else
          {success: false, error: "Move failed"}
        end
      end

      private

      def valid_bounds?
        target_x >= 0 && target_y >= 0 &&
          target_x < match.grid_size && target_y < match.grid_size
      end

      def impassable_tile?
        tile = match.grid_state&.dig(target_y, target_x)
        tile.is_a?(Hash) && tile["passable"] == false
      end

      def in_range?(participant)
        distance = (participant.grid_x - target_x).abs + (participant.grid_y - target_y).abs
        distance <= participant.movement_range
      end

      def log_movement!(participant)
        match.combat_log_entries.create!(
          round_number: match.turn_number,
          sequence: match.combat_log_entries.where(round_number: match.turn_number).count + 1,
          log_type: "movement",
          message: "#{character.name} moved to (#{target_x}, #{target_y})",
          payload: {
            character_id: character.id,
            from: {x: participant.grid_x, y: participant.grid_y},
            to: {x: target_x, y: target_y}
          }
        )
      end
    end
  end
end

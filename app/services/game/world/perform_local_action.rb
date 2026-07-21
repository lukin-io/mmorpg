# frozen_string_literal: true

module Game
  module World
    # Resolves one source-backed local action on the character's current cell.
    # Resource rewards remain intentionally absent until a successful live
    # Neverlands resource result is captured.
    class PerformLocalAction
      Result = Struct.new(:success, :message, :local_action, keyword_init: true)

      def initialize(character:, tile:, local_action_type:)
        @character = character
        @tile = tile
        @local_action_type = local_action_type.to_s
      end

      def call
        return failure("Local action is not on the current cell.") unless tile_matches_position?
        return failure("Local action is not implemented.") unless MapTileTemplate.local_action_implemented?(local_action_type)

        local_action = tile.local_action(local_action_type)
        return failure("Local action is no longer available.") unless local_action

        Result.new(
          success: true,
          message: local_action["result_message"].presence ||
            MapTileTemplate.default_local_action_message(local_action_type),
          local_action:
        )
      end

      private

      attr_reader :character, :tile, :local_action_type

      def tile_matches_position?
        position = character.position
        position.present? &&
          position.zone.name == tile.zone &&
          position.x == tile.x &&
          position.y == tile.y
      end

      def failure(message)
        Result.new(success: false, message:, local_action: nil)
      end
    end
  end
end

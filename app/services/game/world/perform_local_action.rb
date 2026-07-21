# frozen_string_literal: true

module Game
  module World
    # Resolves one source-backed local action on the character's current cell.
    # Resource rewards remain intentionally absent until a successful live
    # Neverlands resource result is captured.
    class PerformLocalAction
      Result = Struct.new(:success, :message, :local_action, :interrupted_by, keyword_init: true)

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

        hostile_npc = hostile_npc_at_tile
        if hostile_npc
          return Result.new(
            success: true,
            message: "#{hostile_npc.display_name} attacks before the action completes.",
            local_action:,
            interrupted_by: hostile_npc
          )
        end

        Result.new(
          success: true,
          message: local_action["result_message"].presence ||
            MapTileTemplate.default_local_action_message(local_action_type),
          local_action:,
          interrupted_by: nil
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

      def hostile_npc_at_tile
        TileNpc
          .includes(:npc_template)
          .hostile
          .find_by(zone: tile.zone, x: tile.x, y: tile.y)
          &.then { |npc| npc if npc.alive? }
      end

      def failure(message)
        Result.new(success: false, message:, local_action: nil, interrupted_by: nil)
      end
    end
  end
end

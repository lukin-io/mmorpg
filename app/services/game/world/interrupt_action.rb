# frozen_string_literal: true

module Game
  module World
    # Resolves whether a valid wilderness action is replaced by the hostile NPC
    # encounter anchored on the character's current cell.
    class InterruptAction
      Result = Struct.new(:interrupted, :match, :npc, :message, keyword_init: true) do
        def interrupted?
          interrupted
        end
      end

      def initialize(character:, return_context: "world")
        @character = character
        @return_context = return_context
      end

      def call
        if (match = active_match)
          return Result.new(
            interrupted: true,
            match:,
            message: "Finish the active fight before continuing."
          )
        end

        npc = hostile_npc_at_current_cell
        return Result.new(interrupted: false) unless npc

        match = StartNpcFight.new(character:, tile_npc: npc, return_context:).call
        Result.new(
          interrupted: true,
          match:,
          npc:,
          message: "#{npc.display_name} attacks before the action completes."
        )
      end

      private

      attr_reader :character, :return_context

      def active_match
        character.arena_participations
          .joins(:arena_match)
          .merge(ArenaMatch.active)
          .order("arena_participations.created_at DESC")
          .first
          &.arena_match
      end

      def hostile_npc_at_current_cell
        position = character.position
        return unless position&.zone&.outdoor?

        npc = TileNpcService.new(
          character:,
          zone: position.zone,
          x: position.x,
          y: position.y
        ).tile_npc

        npc if npc&.alive? && npc.hostile?
      end
    end
  end
end

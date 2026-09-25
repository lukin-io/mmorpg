# frozen_string_literal: true

module Game
  module World
    # Resolves whether a valid wilderness action is replaced by the hostile NPC
    # encounter anchored on the character's current cell.
    #
    # Ashen rule: passive ambushes happen on their own timer (~5 minutes).
    # Forced same-cell fights from Look / Enter / shell actions require bait.
    class InterruptAction
      Result = Struct.new(:interrupted, :match, :npc, :message, :hint, keyword_init: true) do
        def interrupted?
          interrupted
        end
      end

      def initialize(character:, return_context: "world")
        @character = character
        @return_context = return_context
      end

      def call
        Game::Movement::CompleteMove.new(character:).call
        character.with_lock do
          character.reload
          next Result.new(interrupted: false) if character.active_airship_journey

          active_world_action = LocalActionState.new(character:).call
          if (match = active_match)
            # After a fight the player must still reach Character / Inventory
            # (heal scrolls, gear). Do not bounce them back into the arena UI.
            next Result.new(interrupted: false) if shell_navigation?

            next Result.new(
              interrupted: true,
              match:,
              message: I18n.t("game.flashes.fight_still_active")
            )
          end

          if MovementCommand.moving.where(character:).exists?
            next Result.new(interrupted: false) if shell_navigation?

            raise StartNpcFight::FightViolationError, I18n.t("game.flashes.movement_in_progress")
          end
          if active_world_action
            next Result.new(interrupted: false) if shell_navigation?

            raise StartNpcFight::FightViolationError, I18n.t("game.world.local_action_in_progress")
          end

          # Opening Character / Inventory must never force a bait fight.
          next Result.new(interrupted: false) if shell_navigation?

          npc = hostile_npc_at_current_cell
          next Result.new(interrupted: false) unless npc

          bait = Bait.new(character:)
          unless bait.available?
            next Result.new(
              interrupted: false,
              npc:,
              hint: I18n.t("game.world.hostile_without_bait", name: npc.display_name)
            )
          end

          bait.consume!
          match = StartNpcFight.new(character:, tile_npc: npc, return_context:).call
          Result.new(
            interrupted: true,
            match:,
            npc:,
            message: I18n.t("game.world.bait_ambush", name: npc.display_name)
          )
        end
      rescue Bait::MissingBaitError
        Result.new(interrupted: false, hint: I18n.t("game.world.bait_missing"))
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

      def shell_navigation?
        # WorldContextActionsController passes CombatReturnContext.normalize output
        # ({"name"=>"inventory"}), while other callers pass a bare string.
        name = if return_context.respond_to?(:to_h) && !return_context.is_a?(String)
          return_context.to_h.deep_stringify_keys["name"]
        else
          return_context
        end.to_s

        %w[profile inventory].include?(name)
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

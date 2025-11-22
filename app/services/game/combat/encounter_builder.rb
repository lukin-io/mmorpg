# frozen_string_literal: true

module Game
  module Combat
    # EncounterBuilder wires PvE/PvP encounters into Battle + BattleParticipant records.
    #
    # Usage:
    #   battle = Game::Combat::EncounterBuilder.new(initiator:, targets:, mode: :pvp).call
    #
    # Returns:
    #   Battle record with populated participants.
    class EncounterBuilder
      def initialize(initiator:, targets:, mode: :pve, zone: nil, allow_spectators: true)
        @initiator = initiator
        @targets = Array.wrap(targets)
        @mode = mode
        @zone = zone
        @allow_spectators = allow_spectators
      end

      def call
        Battle.transaction do
          battle = Battle.create!(
            battle_type: battle_type_from_mode,
            status: :active,
            initiator:,
            zone: zone || initiator.position&.zone,
            allow_spectators: allow_spectators,
            started_at: Time.current
          )

          add_initiator_participant(battle)
          targets.each { |target| add_target_participant(battle, target) }

          battle.update!(
            initiative_order: battle.battle_participants.order(initiative: :desc).pluck(:id)
          )

          battle
        end
      end

      private

      attr_reader :initiator, :targets, :mode, :zone, :allow_spectators

      def battle_type_from_mode
        case mode.to_sym
        when :pvp then :pvp
        when :arena then :arena
        else
          :pve
        end
      end

      def add_initiator_participant(battle)
        battle.battle_participants.create!(
          character: initiator,
          role: "attacker",
          team: "alpha",
          initiative: initiative_for(initiator),
          hp_remaining: stat_block(initiator)[:hp],
          stat_snapshot: stat_block(initiator)
        )
      end

      def add_target_participant(battle, target)
        attrs = {
          role: role_for(target),
          team: team_for(target),
          initiative: initiative_for(target),
          hp_remaining: stat_block(target)[:hp],
          stat_snapshot: stat_block(target)
        }

        if target.is_a?(Character)
          battle.battle_participants.create!(attrs.merge(character: target))
        else
          battle.battle_participants.create!(attrs.merge(npc_template: target))
        end
      end

      def stat_block(entity)
        stats = entity.respond_to?(:stats) ? entity.stats : default_stats(entity)
        {
          hp: stats.get(:hp) || 100,
          attack: stats.get(:attack) || 5,
          defense: stats.get(:defense) || 3,
          initiative: stats.get(:initiative) || 10
        }
      end

      def initiative_for(entity)
        stat_block(entity)[:initiative]
      end

      def default_stats(entity)
        base = {hp: 100, attack: 5, defense: 3, initiative: 10}
        if entity.respond_to?(:level)
          bonus = entity.level * 2
          base[:hp] += bonus
        end
        Game::Systems::StatBlock.new(base: base)
      end

      def role_for(target)
        target.is_a?(Character) ? "defender" : "npc"
      end

      def team_for(target)
        target.is_a?(Character) ? "bravo" : "pve"
      end
    end
  end
end

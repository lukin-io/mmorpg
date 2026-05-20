# frozen_string_literal: true

module Game
  module Combat
    # LogWriter centralizes persistence of combat log entries for spectators/moderators.
    #
    # Usage:
    #   Game::Combat::LogWriter.new(battle:).append!(message: \"...\")
    #   Game::Combat::LogWriter.new(arena_match:).append!(message: \"...\")
    #
    # Returns:
    #   CombatLogEntry record.
    class LogWriter
      def initialize(battle: nil, arena_match: nil, fight: nil)
        @battle = battle
        @arena_match = arena_match
        @fight = fight || arena_match || battle
        raise ArgumentError, "battle or arena_match is required" unless @fight
      end

      def append!(message:, payload: {}, round_number: current_round_number, sequence_offset: 0, actor: nil, target: nil,
        damage: 0, healing: 0, tags: [], log_type: "action", occurred_at: Time.current,
        action_key: nil, body_part: nil, outcome: nil, actor_team: nil, target_team: nil)
        CombatLogEntry.create!(
          battle: battle_owner,
          arena_match: arena_match_owner,
          round_number:,
          sequence: fight.next_sequence_for(round_number) + sequence_offset,
          occurred_at:,
          log_type:,
          message:,
          payload:,
          actor_id: actor&.id,
          actor_type: actor&.class&.name,
          target_id: target&.id,
          target_type: target&.class&.name,
          damage_amount: damage,
          healing_amount: healing,
          action_key:,
          body_part:,
          outcome:,
          actor_team:,
          target_team:,
          tags:
        )
      end

      private

      attr_reader :battle, :arena_match, :fight

      def battle_owner
        fight if fight.is_a?(Battle)
      end

      def arena_match_owner
        fight if fight.is_a?(ArenaMatch)
      end

      def current_round_number
        if fight.respond_to?(:turn_number)
          fight.turn_number || 1
        elsif fight.respond_to?(:current_turn_number)
          fight.current_turn_number.presence || 1
        else
          1
        end
      end
    end
  end
end

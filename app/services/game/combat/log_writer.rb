# frozen_string_literal: true

module Game
  module Combat
    # LogWriter centralizes persistence of combat log entries for spectators/moderators.
    #
    # Usage:
    #   Game::Combat::LogWriter.new(arena_match:).append!(message: \"...\")
    #
    # Returns:
    #   CombatLogEntry record.
    class LogWriter
      def initialize(arena_match:)
        @arena_match = arena_match
        raise ArgumentError, "arena_match is required" unless @arena_match
      end

      def append!(message:, payload: {}, round_number: current_round_number, sequence_offset: 0, actor: nil, target: nil,
        damage: 0, tags: [], log_type: "action", occurred_at: Time.current,
        action_key: nil, body_part: nil, outcome: nil, actor_team: nil, target_team: nil)
        CombatLogEntry.create!(
          arena_match:,
          round_number:,
          sequence: arena_match.next_sequence_for(round_number) + sequence_offset,
          occurred_at:,
          log_type:,
          message:,
          payload:,
          actor_id: actor&.id,
          actor_type: actor&.class&.name,
          target_id: target&.id,
          target_type: target&.class&.name,
          damage_amount: damage,
          action_key:,
          body_part:,
          outcome:,
          actor_team:,
          target_team:,
          tags:
        )
      end

      private

      attr_reader :arena_match

      def current_round_number
        if arena_match.respond_to?(:current_turn_number)
          arena_match.current_turn_number.presence || 1
        else
          1
        end
      end
    end
  end
end

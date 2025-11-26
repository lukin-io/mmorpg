# frozen_string_literal: true

module Game
  module Combat
    # LogWriter centralizes persistence of combat log entries for spectators/moderators.
    #
    # Usage:
    #   Game::Combat::LogWriter.new(battle:).append!(message: \"...\")
    #
    # Returns:
    #   CombatLogEntry record.
    class LogWriter
      def initialize(battle:)
        @battle = battle
      end

      def append!(message:, payload: {}, round_number: battle.turn_number, sequence_offset: 0, actor: nil, target: nil,
        ability: nil, damage: 0, healing: 0, tags: [])
        CombatLogEntry.create!(
          battle:,
          round_number:,
          sequence: battle.next_sequence_for(round_number) + sequence_offset,
          message:,
          payload:,
          actor_id: actor&.id,
          actor_type: actor&.class&.name,
          target_id: target&.id,
          target_type: target&.class&.name,
          ability: ability,
          damage_amount: damage,
          healing_amount: healing,
          tags:
        )
      end

      private

      attr_reader :battle
    end
  end
end

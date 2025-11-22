# frozen_string_literal: true

module Professions
  module Doctor
    # TraumaResponse shortens post-battle downtime using the Doctor profession bonus.
    #
    # Usage:
    #   Professions::Doctor::TraumaResponse.new(doctor_progress:).apply!(character_position:)
    #
    # Returns:
    #   CharacterPosition after downtime adjustment.
    class TraumaResponse
      def initialize(doctor_progress:)
        @doctor_progress = doctor_progress
      end

      def apply!(character_position:)
        bonus_seconds = doctor_progress.profession.healing_bonus + doctor_progress.skill_level
        return character_position unless character_position.respawn_available_at

        character_position.update!(
          respawn_available_at: [
            character_position.respawn_available_at - bonus_seconds.seconds,
            Time.current
          ].max
        )
        character_position
      end

      private

      attr_reader :doctor_progress
    end
  end
end

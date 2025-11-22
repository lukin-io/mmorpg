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
      def initialize(doctor_progress:, detector: Moderation::Detectors::HealingExploit.new)
        @doctor_progress = doctor_progress
        @detector = detector
      end

      def apply!(character_position:)
        bonus_seconds = doctor_progress.profession.healing_bonus + doctor_progress.skill_level
        return character_position unless character_position.respawn_available_at

        previous_time = character_position.respawn_available_at
        new_time = [
          previous_time - bonus_seconds.seconds,
          Time.current
        ].max

        character_position.update!(respawn_available_at: new_time)
        detector.call(
          character: character_position.character,
          reporter: doctor_progress.user,
          delta_seconds: (previous_time - new_time).to_i
        )
        character_position
      end

      private

      attr_reader :doctor_progress, :detector
    end
  end
end

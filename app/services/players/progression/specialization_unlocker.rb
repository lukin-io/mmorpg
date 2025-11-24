# frozen_string_literal: true

module Players
  module Progression
    # SpecializationUnlocker assigns advanced class specializations once quest requirements are met.
    #
    # Usage:
    #   Players::Progression::SpecializationUnlocker.new(character:, specialization:).unlock!
    class SpecializationUnlocker
      def initialize(character:, specialization:)
        @character = character
        @specialization = specialization
      end

      def unlock!
        validate_requirements!
        character.update!(secondary_specialization: specialization)
      end

      private

      attr_reader :character, :specialization

      def validate_requirements!
        requirements = specialization.unlock_requirements || {}
        quest_key = requirements["quest"]
        return unless quest_key

        quest = Quest.find_by(key: quest_key)
        raise Pundit::NotAuthorizedError, "Specialization quest missing" unless quest

        completed = QuestAssignment.exists?(quest:, character:, status: :completed)
        raise Pundit::NotAuthorizedError, "Specialization quest incomplete" unless completed
      end
    end
  end
end

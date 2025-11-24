# frozen_string_literal: true

module Game
  module Quests
    # TutorialBootstrapper auto-enrolls new characters into foundational tutorial quests (movement/combat/stats/gear).
    #
    # Usage:
    #   Game::Quests::TutorialBootstrapper.new(character:).call
    #
    # Returns:
    #   Array of QuestAssignment records ensured for the character.
    class TutorialBootstrapper
      DEFAULT_KEYS = %w[movement_tutorial combat_tutorial stat_allocation_tutorial gear_upgrade_tutorial].freeze

      def initialize(character:, quest_keys: DEFAULT_KEYS)
        @character = character
        @quest_keys = quest_keys
      end

      def call
        quest_keys.filter_map do |key|
          quest = Quest.find_by(key:)
          next unless quest

          QuestAssignment.find_or_create_by!(quest:, character:) do |assignment|
            assignment.status = :in_progress
            assignment.started_at = Time.current
          end
        end
      end

      private

      attr_reader :character, :quest_keys
    end
  end
end

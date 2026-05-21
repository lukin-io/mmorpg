# frozen_string_literal: true

module Game
  module Quests
    # DynamicQuestRefresher inspects current world and economy state to seed the
    # DynamicQuestGenerator with deterministic triggers. This keeps the quest log
    # reactive without embedding world logic inside controllers.
    #
    # Usage:
    #   Game::Quests::DynamicQuestRefresher.new.refresh!(character: current_character)
    #
    # Returns:
    #   Array of QuestAssignment records that were generated.
    class DynamicQuestRefresher
      def initialize(generator: DynamicQuestGenerator.new)
        @generator = generator
      end

      def refresh!(character:)
        generator.generate!(
          character:,
          triggers: triggers
        )
      end

      private

      attr_reader :generator

      def triggers
        {
          resource_shortage: resource_shortage_key
        }.compact
      end

      def resource_shortage_key
        node = GatheringNode
          .where("next_available_at IS NOT NULL AND next_available_at > ?", Time.current)
          .order(next_available_at: :desc)
          .first
        node&.resource_key
      end
    end
  end
end

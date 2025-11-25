# frozen_string_literal: true

module Game
  module Quests
    # DynamicQuestRefresher inspects current world and economy state to seed the
    # DynamicQuestGenerator with deterministic triggers (resource shortages,
    # contested clan territories, active events). This keeps the quest log
    # feeling reactive without embedding world logic inside controllers.
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
          resource_shortage: resource_shortage_key,
          clan_controlled: contested_territory_key,
          event_key: active_event_slug
        }.compact
      end

      def resource_shortage_key
        node = GatheringNode
          .where("next_available_at IS NOT NULL AND next_available_at > ?", Time.current)
          .order(next_available_at: :desc)
          .first
        node&.resource_key
      end

      def contested_territory_key
        ClanTerritory.order(updated_at: :desc).first&.territory_key
      end

      def active_event_slug
        GameEvent.active.order(updated_at: :desc).first&.slug
      end
    end
  end
end

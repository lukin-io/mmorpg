# frozen_string_literal: true

module Game
  module Quests
    # DynamicQuestGenerator inspects world/clan triggers and assigns matching
    # dynamic quests to a character. It reuses Quest metadata (dynamic_triggers)
    # so designers can author conditional logic per quest.
    #
    # Usage:
    #   Game::Quests::DynamicQuestGenerator.new.generate!(
    #     character:,
    #     triggers: {resource_shortage: "ashen_ore", clan_controlled: "rebellion"}
    #   )
    #
    # Returns:
    #   Array of QuestAssignment records.
    class DynamicQuestGenerator
      def initialize(assignment_class: QuestAssignment)
        @assignment_class = assignment_class
      end

      def generate!(character:, triggers:)
        normalized_triggers = triggers.stringify_keys

        Quest.dynamic.active.filter_map do |quest|
          next unless matches_triggers?(quest, normalized_triggers)

          assignment_class.find_or_create_by!(quest:, character:) do |assignment|
            assignment.status = :pending
            assignment.metadata = assignment.metadata.merge("generated_from" => normalized_triggers)
          end
        end
      end

      private

      attr_reader :assignment_class

      def matches_triggers?(quest, triggers)
        rules = quest.metadata.fetch("dynamic_triggers", {})
        return true if rules.blank?

        rules.all? do |key, value|
          case key.to_s
          when "resource_shortage"
            Array(value).map(&:to_s).include?(triggers["resource_shortage"].to_s)
          when "clan_controlled"
            Array(value).map(&:to_s).include?(triggers["clan_controlled"].to_s)
          when "event_key"
            Array(value).map(&:to_s).include?(triggers["event_key"].to_s)
          else
            triggers[key.to_s] == value
          end
        end
      end
    end
  end
end

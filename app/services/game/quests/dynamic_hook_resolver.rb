# frozen_string_literal: true

module Game
  module Quests
    # DynamicHookResolver ties seasonal/tournament hooks to quest unlocks.
    #
    # Usage:
    #   resolver = Game::Quests::DynamicHookResolver.new
    #   resolver.assign_for(character: char, event_key: "wintertide")
    class DynamicHookResolver
      def initialize(population_directory: Game::World::PopulationDirectory.instance, assignment_class: QuestAssignment)
        @population_directory = population_directory
        @assignment_class = assignment_class
      end

      def assign_for(character:, event_key:)
        quests = quests_for_event(event_key)

        quests.map do |quest|
          assignment_class.find_or_initialize_by(quest:, character:).tap do |assignment|
            assignment.status = :pending if assignment.new_record?
            assignment.metadata = assignment.metadata.merge("triggered_by" => event_key)
            assignment.save!
          end
        end
      end

      def announcer_for(event_key)
        population_directory.npcs.values.find do |npc|
          npc.event_hooks.fetch("seasonal_keys", []).include?(event_key)
        end
      end

      private

      attr_reader :population_directory, :assignment_class

      def quests_for_event(event_key)
        Quest.dynamic.select do |quest|
          quest.metadata.fetch("event_keys", []).include?(event_key)
        end
      end
    end
  end
end

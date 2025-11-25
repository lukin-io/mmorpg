# frozen_string_literal: true

module Game
  module Quests
    # FailureConsequenceHandler applies the failure payload defined on a quest
    # when an assignment is marked failed or abandoned. Payloads can reduce
    # reputation, spawn rival quests, or emit analytics hooks.
    #
    # Usage:
    #   Game::Quests::FailureConsequenceHandler.new(assignment: assignment)
    #     .apply!(reason: "abandoned")
    #
    # Returns:
    #   Boolean indicating whether any consequence was applied.
    class FailureConsequenceHandler
      def initialize(assignment:, analytics_tracker: Analytics::QuestTracker)
        @assignment = assignment
        @analytics_tracker = analytics_tracker
      end

      def apply!(reason:)
        payload = assignment.quest.failure_consequence
        return false if payload.blank?

        ApplicationRecord.transaction do
          adjust_reputation!(payload)
          trigger_follow_up!(payload)
          analytics_tracker.track_failure!(
            quest: assignment.quest,
            character: assignment.character,
            reason: reason
          )
        end
        true
      end

      private

      attr_reader :assignment, :analytics_tracker

      delegate :character, to: :assignment

      def adjust_reputation!(payload)
        delta = payload["reputation_delta"].to_i
        return if delta.zero?

        character.decrement!(:reputation, delta.abs)
      end

      def trigger_follow_up!(payload)
        quest_key = payload["trigger_quest_key"]
        return if quest_key.blank?

        quest = Quest.find_by(key: quest_key)
        return unless quest

        QuestAssignment.find_or_create_by!(quest:, character:) do |assignment|
          assignment.status = :pending
          assignment.metadata = assignment.metadata.merge("triggered_by" => "failure")
        end
      end
    end
  end
end

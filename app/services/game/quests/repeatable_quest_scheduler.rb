# frozen_string_literal: true

module Game
  module Quests
    # RepeatableQuestScheduler refreshes weekly repeatable quests independent of
    # the daily rotation. It ensures players receive a predictable set of
    # high-value tasks without manual GM intervention.
    #
    # Usage:
    #   Game::Quests::RepeatableQuestScheduler.new(character:).refresh!
    #
    # Returns:
    #   Array of QuestAssignment records touched during the refresh.
    class RepeatableQuestScheduler
      def initialize(character:, now: Time.current, assignment_class: QuestAssignment)
        @character = character
        @now = now
        @assignment_class = assignment_class
      end

      def refresh!
        assignments = []
        weekly_quests.find_each do |quest|
          assignment = assignment_class.find_or_initialize_by(quest:, character:)
          next if assignment.completed? && assignment.next_available_at&.future?

          assignment.status = :pending
          assignment.started_at = nil
          assignment.next_available_at = next_weekly_reset
          assignment.save!
          assignments << assignment
        end
        assignments
      end

      private

      attr_reader :character, :now, :assignment_class

      def weekly_quests
        Quest.where(repeatable: true).where(quest_type: [:weekly, :event])
      end

      def next_weekly_reset
        (now.beginning_of_week + 1.week).change(hour: 4)
      end
    end
  end
end

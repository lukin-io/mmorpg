# frozen_string_literal: true

module Game
  module Quests
    # StorylineProgression enforces chapter-based gating (level, reputation,
    # faction alignment) before unlocking quests sequentially for a character.
    # It extends the previous ChainProgression behavior by layering the new gate
    # evaluator and chapter access rules atop the existing quest chain ordering.
    #
    # Usage:
    #   Game::Quests::StorylineProgression.new(character:, quest_chain:).unlock_available!
    #
    # Returns:
    #   Array of QuestAssignment records either created or touched during the call.
    class StorylineProgression
      def initialize(character:, quest_chain:, assignment_class: QuestAssignment, gate_evaluator: QuestGateEvaluator)
        @character = character
        @quest_chain = quest_chain
        @assignment_class = assignment_class
        @gate_evaluator = gate_evaluator
      end

      def unlock_available!
        accessible_ids = accessible_chapter_ids

        quest_chain.quests.chronological.filter_map do |quest|
          next unless quest_accessible?(quest, accessible_ids)
          next unless prerequisites_met?(quest)

          gate_result = gate_evaluator.new(character:, quest:).call
          next unless gate_result.allowed?

          ensure_assignment(quest)
        end
      end

      private

      attr_reader :character, :quest_chain, :assignment_class, :gate_evaluator

      def accessible_chapter_ids
        return [] if quest_chain.quest_chapters.empty?

        blocked = false
        quest_chain.quest_chapters.ordered.each_with_object([]) do |chapter, memo|
          break memo if blocked

          result = gate_evaluator.new(character:, chapter:).call
          if result.allowed?
            memo << chapter.id
          else
            blocked = true
          end
        end
      end

      def quest_accessible?(quest, accessible_ids)
        return true unless quest.quest_chapter_id
        return true if accessible_ids.include?(quest.quest_chapter_id)

        # If there are no accessible chapters because gating failed early, we
        # still want to surface assignments from the first locked chapter so the
        # UI can explain why it is locked. To support this, allow the very first
        # chapter even when ids array is empty.
        accessible_ids.empty? && quest.quest_chapter == quest_chain.quest_chapters.ordered.first
      end

      def ensure_assignment(quest)
        assignment_class.find_or_initialize_by(quest:, character:).tap do |assignment|
          assignment.status ||= default_status_for(quest)
          assignment.started_at ||= Time.current if assignment.in_progress?
          assignment.save!
        end
      end

      def default_status_for(quest)
        if quest.repeatable? || quest.daily?
          :pending
        else
          :in_progress
        end
      end

      def prerequisites_met?(quest)
        previous = quest_chain.quests.where("sequence < ?", quest.sequence).order(sequence: :desc).first
        return true unless previous

        assignment_class.exists?(quest: previous, character:, status: :completed)
      end
    end
  end
end

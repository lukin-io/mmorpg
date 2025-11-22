# frozen_string_literal: true

module Game
  module Quests
    # ChainProgression unlocks sequential quests once prerequisites are completed.
    #
    # Usage:
    #   Game::Quests::ChainProgression.new(character: char, quest_chain: chain).unlock_available!
    #
    # Returns:
    #   Array of QuestAssignment records ensured to exist for the character.
    class ChainProgression
      def initialize(character:, quest_chain:, assignment_class: QuestAssignment)
        @character = character
        @quest_chain = quest_chain
        @assignment_class = assignment_class
      end

      def unlock_available!
        quest_chain.quests.chronological.filter_map do |quest|
          next unless prerequisites_met?(quest)

          assignment = find_or_build_assignment(quest)
          assignment.status ||= assignment.quest.daily? ? :pending : :in_progress
          assignment.started_at ||= Time.current if assignment.in_progress?
          assignment.save!
          assignment
        end
      end

      private

      attr_reader :character, :quest_chain, :assignment_class

      def find_or_build_assignment(quest)
        assignment_class.find_or_initialize_by(quest:, character:)
      end

      def prerequisites_met?(quest)
        previous = quest_chain.quests.where("sequence < ?", quest.sequence).order(sequence: :desc).first
        return true unless previous

        assignment_class.exists?(quest: previous, character:, status: :completed)
      end
    end
  end
end

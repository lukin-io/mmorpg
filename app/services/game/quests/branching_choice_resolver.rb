# frozen_string_literal: true

module Game
  module Quests
    # BranchingChoiceResolver applies the side effects defined on a QuestStep's
    # branching outcomes when a player makes a dialogue choice. Effects can
    # adjust reputation/faction alignment, set story flags, and unlock or lock
    # follow-up quests.
    #
    # Usage:
    #   Game::Quests::BranchingChoiceResolver.new(assignment:, step:)
    #     .apply(choice_key: "aid_rebels")
    #
    # Returns:
    #   Result struct responding to #status, #flags, #reason.
    class BranchingChoiceResolver
      Result = Struct.new(:status, :flags, :reason, keyword_init: true) do
        def status
          value = self[:status]
          (value || :continue).to_sym
        end

        def flags
          Array(self[:flags])
        end
      end

      def initialize(assignment:, step:, gate_evaluator: QuestGateEvaluator)
        @assignment = assignment
        @step = step
        @gate_evaluator = gate_evaluator
      end

      def apply(choice_key:)
        payload = consequence(choice_key).deep_stringify_keys

        ApplicationRecord.transaction do
          adjust_reputation!(payload)
          adjust_alignment!(payload)
          grant_flags!(payload)
          unlock_quests!(payload)
          lock_quests!(payload)
        end

        Result.new(
          status: (payload["result"] || :continue).to_sym,
          flags: Array(payload["grant_flags"]),
          reason: payload["failure_reason"]
        )
      end

      private

      attr_reader :assignment, :step, :gate_evaluator

      delegate :character, to: :assignment

      def quest
        assignment.quest
      end

      def consequence(choice_key)
        step.consequence_for(choice_key).presence ||
          raise(ArgumentError, "Unknown choice #{choice_key} for quest step #{step.id}")
      end

      def adjust_reputation!(payload)
        delta = payload["reputation_delta"].to_i
        return if delta.zero?

        character.increment!(:reputation, delta)
      end

      def adjust_alignment!(payload)
        alignment = payload["faction_alignment"]
        return if alignment.blank?

        character.update!(
          faction_alignment: alignment,
          alignment_score: character.alignment_score + payload.fetch("alignment_score_delta", 0).to_i
        )
      end

      def grant_flags!(payload)
        flags = Array(payload["grant_flags"])
        return if flags.empty?

        assignment.append_story_flags!(flags)
      end

      def unlock_quests!(payload)
        quest_keys = Array(payload["unlock_quest_keys"])
        return if quest_keys.empty?

        Quest.where(key: quest_keys).find_each do |next_quest|
          QuestAssignment.find_or_create_by!(quest: next_quest, character:) do |assignment|
            assignment.status = :pending
          end
        end
      end

      def lock_quests!(payload)
        quest_keys = Array(payload["lock_quest_keys"])
        return if quest_keys.empty?

        Quest.where(key: quest_keys).find_each do |locked_quest|
          QuestAssignment.find_by(quest: locked_quest, character:)&.update!(status: :failed)
        end
      end
    end
  end
end

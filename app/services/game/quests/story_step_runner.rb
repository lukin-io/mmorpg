# frozen_string_literal: true

module Game
  module Quests
    # StoryStepRunner advances a quest assignment through its authored QuestSteps,
    # applying branching choice consequences and marking completion/failure
    # metadata for the UI. It does not award rewards—that is handled by
    # Game::Quests::RewardService once the assignment is completed.
    #
    # Usage:
    #   Game::Quests::StoryStepRunner.new(assignment: assignment)
    #     .call(choice_key: "support_clan")
    #
    # Returns:
    #   Result object responding to #completed?, #failed?, and exposing the
    #   current/next steps for rendering.
    class StoryStepRunner
      Result = Struct.new(
        :assignment,
        :current_step,
        :next_step,
        :completed,
        :failed,
        keyword_init: true
      ) do
        alias_method :completed?, :completed
        alias_method :failed?, :failed
      end

      def initialize(
        assignment:,
        branching_resolver: BranchingChoiceResolver,
        failure_handler: FailureConsequenceHandler.new(assignment: assignment)
      )
        @assignment = assignment
        @branching_resolver_class = branching_resolver
        @failure_handler = failure_handler
      end

      def call(choice_key: nil)
        return Result.new(assignment:, completed: true) if assignment.story_complete?

        ApplicationRecord.transaction do
          step = current_step
          raise ArgumentError, "No quest steps defined" unless step

          handle_choice(step, choice_key) if choice_key.present?
          advance_progress(step) unless assignment.story_complete?

          Result.new(
            assignment: assignment,
            current_step: step,
            next_step: next_step(step),
            completed: assignment.story_complete?,
            failed: assignment.failed?
          )
        end
      end

      private

      attr_reader :assignment, :branching_resolver_class, :failure_handler

      def quest
        assignment.quest
      end

      def ordered_steps
        @ordered_steps ||= quest.quest_steps.ordered
      end

      def current_step
        ordered_steps.find_by(position: assignment.current_step_position) || ordered_steps.first
      end

      def next_step(step)
        ordered_steps.find_by(position: step.position + 1)
      end

      def handle_choice(step, choice_key)
        resolver = branching_resolver_class.new(assignment:, step:)
        outcome = resolver.apply(choice_key: choice_key)
        assignment.record_story_progress!(
          "decisions" => assignment.story_decisions.merge(step.position.to_s => choice_key)
        )

        case outcome.status
        when :fail
          assignment.update!(status: :failed)
          failure_handler.apply!(reason: outcome.reason || "branch_failure")
        when :complete
          assignment.record_story_progress!("completed" => true)
        end

        assignment.append_story_flags!(outcome.flags) if outcome.flags.any?
      end

      def advance_progress(step)
        new_position = step.position + 1
        attrs = {"current_step_position" => new_position}

        unless next_step(step)
          attrs["completed"] = true
        end

        assignment.record_story_progress!(attrs)
      end
    end
  end
end

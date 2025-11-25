# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::StoryStepRunner do
  subject(:runner) { described_class.new(assignment: assignment, branching_resolver: resolver_class, failure_handler: failure_handler) }

  let(:quest) { create(:quest) }
  let!(:step_one) { create(:quest_step, quest:, position: 1, step_type: "dialogue", branching_outcomes: branching_payload) }
  let!(:step_two) { create(:quest_step, quest:, position: 2, step_type: "objective") }
  let(:assignment) { create(:quest_assignment, quest:, status: :in_progress, progress: {"current_step_position" => 1}) }
  let(:branching_payload) do
    {
      "choices" => [
        {"key" => "aid", "label" => "Aid the guard"},
        {"key" => "ignore", "label" => "Ignore"}
      ],
      "consequences" => {
        "aid" => {"result" => "continue", "grant_flags" => ["helped_guard"]},
        "ignore" => {"result" => "fail", "failure_reason" => "cowardice"}
      }
    }
  end
  let(:resolver_class) do
    Class.new do
      def initialize(assignment:, step:)
        @assignment = assignment
        @step = step
      end

      def apply(choice_key:)
        consequence = @step.branching_outcomes["consequences"][choice_key]
        Game::Quests::BranchingChoiceResolver::Result.new(
          status: (consequence["result"] || :continue),
          flags: Array(consequence["grant_flags"]),
          reason: consequence["failure_reason"]
        )
      end
    end
  end
  let(:failure_handler) { instance_double(Game::Quests::FailureConsequenceHandler, apply!: true) }

  describe "#call" do
    it "advances to the next step" do
      result = runner.call

      expect(result.current_step).to eq(step_one)
      expect(result.next_step).to eq(step_two)
      expect(result).not_to be_completed
      expect(assignment.reload.current_step_position).to eq(2)
    end

    it "applies branching choices and flags" do
      result = runner.call(choice_key: "aid")

      expect(result.assignment.metadata["story_flags"]).to include("helped_guard")
      expect(result).not_to be_failed
    end

    it "marks assignment failed when choice outcome fails" do
      runner.call(choice_key: "ignore")

      expect(assignment.reload).to be_failed
      expect(failure_handler).to have_received(:apply!).with(reason: "cowardice")
    end
  end
end

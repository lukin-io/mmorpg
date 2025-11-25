# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::DynamicQuestGenerator do
  let(:character) { create(:character) }
  let!(:matching_quest) do
    create(:quest,
      quest_type: :dynamic,
      metadata: {"dynamic_triggers" => {"resource_shortage" => ["ashen_ore"], "event_key" => ["festival"]}})
  end
  let!(:non_matching_quest) do
    create(:quest,
      quest_type: :dynamic,
      metadata: {"dynamic_triggers" => {"resource_shortage" => ["moonleaf"]}})
  end

  describe "#generate!" do
    it "assigns quests whose triggers match the provided world state" do
      assignments = described_class.new.generate!(
        character:,
        triggers: {resource_shortage: "ashen_ore", event_key: "festival"}
      )

      expect(assignments.map(&:quest)).to contain_exactly(matching_quest)
      expect(assignments.first.metadata["generated_from"]["resource_shortage"]).to eq("ashen_ore")
    end

    it "skips quests whose triggers do not match" do
      assignments = described_class.new.generate!(
        character:,
        triggers: {resource_shortage: "unknown"}
      )

      expect(assignments).to be_empty
      expect(QuestAssignment.exists?(quest: non_matching_quest, character:)).to be(false)
    end
  end
end

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
      result = described_class.new.generate!(
        character:,
        triggers: {resource_shortage: "ashen_ore", event_key: "festival"}
      )

      expect(result.success).to be(true)
      expect(result.assignments.map(&:quest)).to include(matching_quest)
      expect(result.assignments.first.metadata["generated_from"]["resource_shortage"]).to eq("ashen_ore")
    end

    it "skips existing quests whose triggers do not match" do
      result = described_class.new.generate!(
        character:,
        triggers: {resource_shortage: "unknown"}
      )

      expect(result.success).to be(true)
      # Should not assign the non_matching_quest (which needs moonleaf)
      expect(QuestAssignment.exists?(quest: non_matching_quest, character:)).to be(false)
      # May generate procedural quests based on the trigger
      expect(result.assignments.map(&:quest)).not_to include(non_matching_quest)
    end
  end
end

require "rails_helper"

RSpec.describe Players::Progression::RespecService do
  let(:character) do
    create(
      :character,
      stat_points_available: 0,
      skill_points_available: 0,
      allocated_stats: {"strength" => 3}
    )
  end
  let(:skill_node) { create(:skill_node, skill_tree: create(:skill_tree, character_class: character.character_class)) }
  let!(:character_skill) { create(:character_skill, character:, skill_node:) }

  describe "quest-driven respec" do
    let(:quest_chain) { create(:quest_chain) }
    let(:quest) { create(:quest, quest_chain:, key: "respec_ritual") }

    before do
      create(:quest_assignment, quest:, character:, status: :completed)
    end

    it "refunds stats and skills when the quest requirement is met" do
      described_class.new(character:, source: :quest, quest_key: quest.key).call!

      character.reload
      expect(character.stat_points_available).to eq(3)
      expect(character.skill_points_available).to eq(1)
      expect(character.character_skills).to be_empty
      expect(character.allocated_stats).to be_empty
    end
  end

  describe "premium token respec" do
    before do
      character.user.update!(premium_tokens_balance: 50)
    end

    it "charges premium tokens and refunds allocations" do
      described_class.new(character:, source: :premium, premium_cost: 25).call!

      expect(character.user.reload.premium_tokens_balance).to eq(25)
      expect(character.reload.stat_points_available).to eq(3)
    end
  end
end

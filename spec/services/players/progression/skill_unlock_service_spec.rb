require "rails_helper"

RSpec.describe Players::Progression::SkillUnlockService do
  let(:character) { create(:character, level: 10, skill_points_available: 2) }
  let(:skill_tree) { create(:skill_tree, character_class: character.character_class) }
  let(:skill_node) do
    create(:skill_node, skill_tree:, requirements: {"level" => 5, "quest" => "skill_unlock_trial"})
  end
  let(:quest_chain) { create(:quest_chain) }
  let(:quest) { create(:quest, quest_chain:, key: "skill_unlock_trial") }

  before do
    create(:quest_assignment, quest:, character:, status: :completed)
  end

  it "unlocks the node when requirements are satisfied" do
    expect {
      described_class.new(character:, skill_node:).unlock!
    }.to change(CharacterSkill, :count).by(1)

    expect(character.reload.skill_points_available).to eq(1)
  end

  it "raises when quest requirement is missing" do
    QuestAssignment.delete_all

    expect {
      described_class.new(character:, skill_node:).unlock!
    }.to raise_error(Pundit::NotAuthorizedError)
  end
end

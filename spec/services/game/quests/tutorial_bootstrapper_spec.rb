require "rails_helper"

RSpec.describe Game::Quests::TutorialBootstrapper do
  let(:character) { create(:character) }
  let(:quest_chain) { create(:quest_chain) }

  before do
    %w[movement_tutorial combat_tutorial stat_allocation_tutorial gear_upgrade_tutorial].each do |key|
      create(:quest, quest_chain:, key:)
    end
  end

  it "creates tutorial quest assignments for the character" do
    assignments = described_class.new(character:).call

    expect(assignments.count).to eq(4)
    expect(character.quest_assignments.pluck(:status).uniq).to eq(["in_progress"])
  end
end

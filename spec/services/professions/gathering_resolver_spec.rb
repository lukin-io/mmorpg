require "rails_helper"

RSpec.describe Professions::GatheringResolver do
  let(:profession) { create(:profession, category: "gathering", gathering: true) }
  let(:progress) { create(:profession_progress, profession:, slot_kind: "gathering", skill_level: 8) }
  let(:zone) { create(:zone, biome: "forest") }
  let(:node) { create(:gathering_node, profession:, zone:, difficulty: 3, rewards: {"herb" => 1}) }

  it "awards rewards and schedules respawn" do
    result = described_class.new(progress:, node:, rng: Random.new(1)).harvest!

    expect(result[:success]).to be(true)
    expect(result[:rewards]).to eq({"herb" => 1})
    expect(node.reload.next_available_at).to be_present
  end

  it "raises when attempting with wrong profession" do
    other_progress = create(:profession_progress, slot_kind: "primary")

    expect {
      described_class.new(progress: other_progress, node:, rng: Random.new(1)).harvest!
    }.to raise_error(Pundit::NotAuthorizedError)
  end
end

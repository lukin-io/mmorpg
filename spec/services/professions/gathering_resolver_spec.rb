require "rails_helper"

RSpec.describe Professions::GatheringResolver do
  let(:profession) { create(:profession, name: "Herbalism", gathering: true) }
  let(:progress) { create(:profession_progress, profession:, skill_level: 5) }
  let(:zone) { create(:zone) }
  let(:node) { create(:gathering_node, profession:, zone:, difficulty: 3, rewards: {"herb" => 1}) }

  it "returns rewards when success check passes" do
    result = described_class.new(progress:, node:, rng: Random.new(1)).harvest!

    expect(result[:success]).to be(true)
    expect(result[:rewards]).to eq({"herb" => 1})
  end
end

require "rails_helper"

RSpec.describe Professions::CraftingOutcomeCalculator do
  let(:progress) { create(:profession_progress, skill_level: 10) }
  let(:recipe) { create(:recipe, requirements: {"skill_level" => 5}, risk_level: "moderate") }
  let(:station) { create(:crafting_station, station_archetype: "city") }

  it "provides success chance and quality tier" do
    preview = described_class.new(progress:, recipe:, station:).preview

    expect(preview.success_chance).to be_between(15, 98)
    expect(preview.quality_tier).to be_present
    expect(preview.quality_score).to be >= 0
  end
end

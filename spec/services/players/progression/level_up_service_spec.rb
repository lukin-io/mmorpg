require "rails_helper"

RSpec.describe Players::Progression::LevelUpService do
  let(:character) { create(:character) }

  it "awards levels and stat points when XP threshold is met" do
    described_class.new(character:).apply_experience!(400)

    expect(character.reload.level).to be > 1
    expect(character.stat_points_available).to be_positive
    expect(character.last_level_up_at).to be_present
  end
end

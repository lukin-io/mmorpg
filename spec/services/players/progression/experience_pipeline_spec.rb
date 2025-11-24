require "rails_helper"

RSpec.describe Players::Progression::ExperiencePipeline do
  let(:character) { create(:character, experience: 0) }

  it "tracks XP allocation per source and applies it to the character" do
    described_class.new(character:).grant!(quest: 50, combat: 25)

    character.reload
    expect(character.progression_sources["quest"]).to eq(50)
    expect(character.progression_sources["combat"]).to eq(25)
    expect(character.experience).to eq(75)
  end
end

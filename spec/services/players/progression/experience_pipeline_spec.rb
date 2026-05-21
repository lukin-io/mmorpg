require "rails_helper"

RSpec.describe Players::Progression::ExperiencePipeline do
  let(:character) { create(:character, experience: 0) }

  it "tracks XP allocation per source and applies it to the character" do
    described_class.new(character:).grant!(combat: 50, gathering: 25)

    character.reload
    expect(character.progression_sources["combat"]).to eq(50)
    expect(character.progression_sources["gathering"]).to eq(25)
    expect(character.experience).to eq(75)
  end
end

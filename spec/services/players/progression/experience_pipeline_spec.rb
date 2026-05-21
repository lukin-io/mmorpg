require "rails_helper"

RSpec.describe Players::Progression::ExperiencePipeline do
  let(:character) { create(:character, experience: 0) }

  it "tracks XP allocation per source and applies it to the character" do
    described_class.new(character:).grant!(combat: 50, unknown_source: 25)

    character.reload
    expect(character.progression_sources["combat"]).to eq(50)
    expect(character.progression_sources).not_to have_key("unknown_source")
    expect(character.experience).to eq(50)
  end
end

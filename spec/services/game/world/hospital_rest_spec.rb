# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::HospitalRest do
  let(:character) { create(:character, current_hp: 1, max_hp: 100, current_mp: 1, max_mp: 50) }

  it "restores vitals when out of combat" do
    result = described_class.new(character:).call

    expect(result.success).to be(true)
    expect(character.reload).to have_attributes(
      current_hp: character.effective_max_hp,
      current_mp: character.effective_max_mp
    )
  end

  it "clears ashen injuries while resting" do
    Game::Combat::InjuryState.new(character:).apply!(severity: "heavy", duration: 1.hour)

    result = described_class.new(character:).call

    expect(result.success).to be(true)
    expect(Game::Combat::InjuryState.new(character: character.reload).any?).to be(false)
  end

  it "rejects rest during combat" do
    character.update!(in_combat: true, last_combat_at: Time.current)

    result = described_class.new(character:).call

    expect(result.success).to be(false)
    expect(character.reload.current_hp).to eq(1)
  end
end

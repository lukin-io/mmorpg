# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TavernRest do
  let(:character) { create(:character, current_hp: 1, max_hp: 100, current_mp: 1, max_mp: 50) }

  it "restores vitals without clearing injuries" do
    Game::Combat::InjuryState.new(character:).apply!(severity: "light", duration: 1.hour)

    result = described_class.new(character:).call

    expect(result.success).to be(true)
    expect(character.reload).to have_attributes(
      current_hp: character.effective_max_hp,
      current_mp: character.effective_max_mp
    )
    expect(Game::Combat::InjuryState.new(character:).any?).to be(true)
  end

  it "rejects when already full" do
    character.update!(
      current_hp: character.effective_max_hp,
      current_mp: character.effective_max_mp,
      fatigue_percent: 0,
      fatigue_updated_at: Time.current
    )

    result = described_class.new(character:).call

    expect(result.success).to be(false)
  end

  it "clears fatigue when vitals are already full" do
    character.update!(
      current_hp: character.effective_max_hp,
      current_mp: character.effective_max_mp,
      fatigue_percent: 40,
      fatigue_updated_at: Time.current
    )

    result = described_class.new(character:).call

    expect(result.success).to be(true)
    expect(character.reload.fatigue_percent).to eq(0)
  end

  it "rejects during combat" do
    character.update!(in_combat: true, last_combat_at: Time.current)

    result = described_class.new(character:).call

    expect(result.success).to be(false)
    expect(character.reload.current_hp).to eq(1)
  end
end

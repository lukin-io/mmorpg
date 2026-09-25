# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TempleBlessing do
  let(:character) { create(:character) }

  before do
    character.user.create_currency_wallet!(nv_balance: 20)
  end

  it "clears light injuries for NV" do
    Game::Combat::InjuryState.new(character:).apply!(severity: "light", duration: 1.hour)
    Game::Combat::InjuryState.new(character:).apply!(severity: "heavy", duration: 1.hour)

    result = described_class.new(character:).call

    expect(result.success).to be(true)
    state = Game::Combat::InjuryState.new(character: character.reload)
    expect(state.active.map { |r| r["severity"] }).to eq(["heavy"])
    expect(character.user.currency_wallet.reload.nv_balance).to eq(15)
  end

  it "rejects when there is no light injury" do
    result = described_class.new(character:).call

    expect(result.success).to be(false)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(20)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::InjuryState do
  let(:character) { create(:character) }
  let(:clock) { -> { Time.zone.parse("2026-09-13 12:00:00") } }
  subject(:state) { described_class.new(character:, clock:) }

  it "clears light injuries and keeps heavy ones" do
    state.apply!(severity: "light", duration: 1.hour)
    state.apply!(severity: "heavy", duration: 1.hour)

    expect(state.clear_light!).to eq(1)
    expect(state.blocks_movement?).to be(true)
    expect(state.summary).to include(I18n.t("game.injuries.severity.heavy"))
  end

  it "includes remaining untreated time in the summary" do
    state.apply!(severity: "combat", duration: 12.hours)

    expect(state.summary).to match(/боевая|combat/i)
    expect(state.summary).to match(/11ч|11h|12ч|12h/)
    expect(state.combat_trauma?).to be(true)
  end
end

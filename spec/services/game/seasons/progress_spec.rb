# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Seasons::Progress do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:wallet) do
    w = user.currency_wallet || user.create_currency_wallet!(nv_balance: 0)
    w.update!(veil_marks: 100)
    w
  end

  before do
    wallet
    Game::Professions::Templates.ensure_craft_items!
  end

  it "grants season XP and unlocks free track claims" do
    progress = described_class.new(character:)
    expect(progress.add_xp!(50).success).to be(true)

    snap = progress.snapshot
    expect(snap[:xp]).to eq(50)
    expect(snap[:free_levels].map { |r| r["level"].to_i }).to include(1, 2)

    claim = progress.claim!(track: :free, level: 1)
    expect(claim.success).to be(true)
    expect(wallet.reload.nv_balance.to_i).to be >= 30
  end

  it "gates premium track behind VM unlock" do
    progress = described_class.new(character:)
    progress.add_xp!(50)
    deny = progress.claim!(track: :premium, level: 1)
    expect(deny.success).to be(false)

    unlock = progress.unlock_premium!
    expect(unlock.success).to be(true), -> { unlock.message }
    expect(wallet.reload.veil_marks.to_i).to eq(65)

    claim = progress.claim!(track: :premium, level: 1)
    expect(claim.success).to be(true)
  end
end

RSpec.describe Game::Seasons::Catalog do
  it "boosts seasonal demand keys while the season is active" do
    expect(described_class.active?).to be(true)
    expect(described_class.demand_multiplier("coal_chunk")).to eq(1.25)
    expect(described_class.demand_multiplier("wood_chips")).to eq(1.0)
  end
end

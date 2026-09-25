# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Seasons::Shop do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:wallet) do
    w = user.currency_wallet || user.create_currency_wallet!(nv_balance: 200)
    w.update!(veil_marks: 50)
    w
  end

  before do
    wallet
    Game::Professions::Templates.ensure_craft_items!
  end

  it "sells a once-per-day convenience offer for VM and grants season XP" do
    result = described_class.new(character:, offer_key: "xp_flask").buy!
    expect(result.success).to be(true), -> { result.message }
    expect(wallet.reload.veil_marks.to_i).to eq(42)
    expect(Game::Seasons::Progress.new(character:).snapshot[:xp]).to eq(80)

    deny = described_class.new(character:, offer_key: "xp_flask").buy!
    expect(deny.success).to be(false)
    expect(deny.message).to eq(I18n.t("game.season.shop_once_day"))
  end
end

RSpec.describe Game::Seasons::DailyCheckin do
  let(:character) { create(:character) }

  it "grants season XP once per UTC day" do
    first = described_class.new(character:).call
    expect(first.granted).to be(true)
    expect(first.xp).to eq(15)

    second = described_class.new(character:).call
    expect(second.granted).to be(false)
  end
end

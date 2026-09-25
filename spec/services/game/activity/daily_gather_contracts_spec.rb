# frozen_string_literal: true

require "rails_helper"

RSpec.describe "daily gather contracts" do
  let(:character) { create(:character) }

  it "materializes herbalist and fisher contracts without duplicating the day" do
    tracker = Game::Activity::Tracker.new(character:)
    2.times { tracker.ensure_daily_contracts! }

    expect(DailyActivityContract.where(character:, contract_key: %w[daily_herbalist daily_fisher]).count).to eq(2)
  end

  it "claims a completed NV reward only once" do
    row = DailyActivityContract.create!(
      character:, day_key: Time.current.utc.strftime("%Y-%m-%d"),
      contract_key: "daily_herbalist", kind: "gather_herb",
      target: 1, progress: 1, reward: {"nv" => 30}, completed_at: Time.current
    )
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    before = wallet.nv_balance

    first = Game::Activity::ClaimReward.new(character:, kind: "contract", id: row.id).call
    second = Game::Activity::ClaimReward.new(character:, kind: "contract", id: row.id).call

    expect(first.success?).to be(true)
    expect(second.success?).to be(false)
    expect(wallet.reload.nv_balance).to eq(before + 30)
  end
end

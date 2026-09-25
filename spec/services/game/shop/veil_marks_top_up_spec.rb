# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::VeilMarksTopUp do
  around do |example|
    previous = ENV["ALLOW_STUB_IAP"]
    ENV["ALLOW_STUB_IAP"] = "true"
    example.run
  ensure
    ENV["ALLOW_STUB_IAP"] = previous
  end

  it "grants sandbox VM and enforces the cooldown" do
    character = create(:character)
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    wallet.update!(veil_marks: 5)
    clock = -> { Time.zone.parse("2026-09-13 12:00:00") }

    first = described_class.new(character:, clock:).call
    expect(first.success).to be(true)
    expect(wallet.reload.veil_marks).to eq(55)

    second = described_class.new(character: character.reload, clock:).call
    expect(second.success).to be(false)
    expect(wallet.reload.veil_marks).to eq(55)

    later = described_class.new(
      character:,
      clock: -> { Time.zone.parse("2026-09-13 13:00:01") }
    ).call
    expect(later.success).to be(true)
    expect(wallet.reload.veil_marks).to eq(105)
  end
end

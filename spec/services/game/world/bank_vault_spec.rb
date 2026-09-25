# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::BankVault do
  let(:character) { create(:character) }

  before do
    character.user.create_currency_wallet!(nv_balance: 50)
  end

  it "deposits and withdraws NV through the vault" do
    deposit = described_class.new(character:, amount: 20, action: "deposit").call
    expect(deposit.success).to be(true)
    expect(described_class.balance_for(character.reload)).to eq(20)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(30)

    withdraw = described_class.new(character:, amount: 5, action: "withdraw").call
    expect(withdraw.success).to be(true)
    expect(described_class.balance_for(character.reload)).to eq(15)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(35)
  end

  it "rejects overdraft from the vault" do
    result = described_class.new(character:, amount: 1, action: "withdraw").call
    expect(result.success).to be(false)
  end
end

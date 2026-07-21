# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyTransaction, type: :model do
  let(:wallet) { create(:user).currency_wallet }

  it "stores signed fractional amounts and fractional resulting balances" do
    transaction = wallet.currency_transactions.create!(
      amount: BigDecimal("-0.25"),
      balance_after: BigDecimal("12.50"),
      reason: "inventory.money_transfer.sent"
    )

    expect(described_class.columns_hash.fetch("amount").type).to eq(:decimal)
    expect(described_class.columns_hash.fetch("balance_after").type).to eq(:decimal)
    expect(transaction.reload).to have_attributes(
      amount: BigDecimal("-0.25"),
      balance_after: BigDecimal("12.50")
    )
  end

  it "rejects zero, null, or a negative resulting balance" do
    transaction = described_class.new(currency_wallet: wallet, reason: "edge")

    transaction.amount = 0
    transaction.balance_after = 0
    expect(transaction).not_to be_valid

    transaction.amount = nil
    expect(transaction).not_to be_valid

    transaction.amount = BigDecimal("0.01")
    transaction.balance_after = BigDecimal("-0.01")
    expect(transaction).not_to be_valid
  end
end

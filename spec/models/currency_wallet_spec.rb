# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyWallet, type: :model do
  it "stores NV as a two-decimal amount" do
    user = create(:user, :with_fractional_nv_balance)

    expect(described_class.columns_hash.fetch("nv_balance").type).to eq(:decimal)
    expect(user.currency_wallet.reload.nv_balance).to eq(BigDecimal("12.50"))
  end

  it "accepts the precision boundary" do
    user = create(:user, :with_maximum_nv_balance)

    expect(user.currency_wallet.reload.nv_balance).to eq(BigDecimal("9999999999.99"))
  end

  it "rejects a negative or null balance" do
    wallet = create(:user).currency_wallet

    wallet.nv_balance = BigDecimal("-0.01")
    expect(wallet).not_to be_valid

    wallet.nv_balance = nil
    expect(wallet).not_to be_valid
  end
end

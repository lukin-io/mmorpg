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

  it "rejects non-finite and out-of-storage balances in the model and through direct SQL" do
    wallet = create(:user).currency_wallet

    [BigDecimal("NaN"), BigDecimal("Infinity"), BigDecimal("-Infinity"), BigDecimal("10000000000")].each do |value|
      wallet.nv_balance = value
      expect(wallet).not_to be_valid
      expect do
        described_class.transaction(requires_new: true) { described_class.where(id: wallet.id).update_all(nv_balance: value) }
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    expect(wallet.reload.nv_balance).to eq(0)
  end

  it "rejects a negative balance when validation is bypassed" do
    wallet = create(:user).currency_wallet

    expect do
      described_class.transaction(requires_new: true) { described_class.where(id: wallet.id).update_all(nv_balance: -1) }
    end.to raise_error(ActiveRecord::StatementInvalid, /currency_wallets_bounded_balance/)

    expect(wallet.reload.nv_balance).to eq(0)
  end
end

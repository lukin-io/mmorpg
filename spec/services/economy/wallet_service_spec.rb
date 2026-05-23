require "rails_helper"

RSpec.describe Economy::WalletService do
  let(:user) { create(:user) }
  let(:wallet) { user.currency_wallet }

  describe "#adjust!" do
    it "credits NV and records transaction" do
      service = described_class.new(wallet: wallet)

      expect do
        service.adjust!(amount: 100, reason: "combat.reward")
      end.to change { wallet.reload.nv_balance }.by(100)

      transaction = wallet.currency_transactions.recent.first
      expect(transaction.amount).to eq(100)
      expect(transaction.balance_after).to eq(100)
      expect(transaction.reason).to eq("combat.reward")
    end

    it "debits NV when enough balance exists" do
      wallet.update!(nv_balance: 100)
      service = described_class.new(wallet: wallet)

      expect do
        service.adjust!(amount: -40, reason: "shop.buy")
      end.to change { wallet.reload.nv_balance }.from(100).to(60)

      transaction = wallet.currency_transactions.recent.first
      expect(transaction.amount).to eq(-40)
      expect(transaction.balance_after).to eq(60)
    end

    it "raises when attempting to overspend" do
      service = described_class.new(wallet: wallet)

      expect do
        service.adjust!(amount: -5, reason: "shop.buy")
      end.to raise_error(Economy::WalletService::InsufficientFundsError)
    end
  end
end

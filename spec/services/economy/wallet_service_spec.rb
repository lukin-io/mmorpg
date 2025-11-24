require "rails_helper"

RSpec.describe Economy::WalletService do
  let(:user) { create(:user) }
  let(:wallet) { user.currency_wallet }

  describe "#adjust!" do
    it "credits within soft cap and records transaction" do
      service = described_class.new(wallet: wallet)

      expect do
        service.adjust!(currency: :gold, amount: 100, reason: "quest.reward")
      end.to change { wallet.reload.gold_balance }.by(100)

      transaction = wallet.currency_transactions.recent.first
      expect(transaction.currency_type).to eq("gold")
      expect(transaction.amount).to eq(100)
      expect(transaction.balance_after).to eq(100)
    end

    it "routes overflow into a sink when soft cap reached" do
      wallet.update!(gold_balance: wallet.gold_soft_cap - 10)
      service = described_class.new(wallet: wallet)

      service.adjust!(currency: :gold, amount: 50, reason: "event.reward")

      wallet.reload
      expect(wallet.gold_balance).to eq(wallet.gold_soft_cap)
      expect(wallet.sink_totals_for(:gold)).to eq(40)
    end

    it "raises when attempting to overspend" do
      service = described_class.new(wallet: wallet)

      expect do
        service.adjust!(currency: :gold, amount: -5, reason: "test")
      end.to raise_error(Economy::WalletService::InsufficientFundsError)
    end
  end
end

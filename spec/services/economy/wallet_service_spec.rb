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

    it "rolls back a balance adjustment when its ledger fails inside a continuing outer transaction" do
      wallet.update!(nv_balance: 100)
      service = described_class.new(wallet:)

      ApplicationRecord.transaction do
        expect { service.adjust!(amount: 10, reason: nil) }.to raise_error(ActiveRecord::RecordInvalid)
        user.update!(profile_name: "Continued outer work")
      end

      expect(user.reload.profile_name).to eq("Continued outer work")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
    end

    it "keeps a successful nested adjustment subject to its caller's rollback" do
      wallet.update!(nv_balance: 100)

      ApplicationRecord.transaction(requires_new: true) do
        described_class.new(wallet:).adjust!(amount: 10, reason: "test.credit")
        raise ActiveRecord::Rollback
      end

      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
    end
  end
end

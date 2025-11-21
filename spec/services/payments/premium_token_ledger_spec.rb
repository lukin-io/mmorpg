require "rails_helper"

RSpec.describe Payments::PremiumTokenLedger do
  describe ".credit" do
    it "increments user balance and records entry" do
      user = create(:user, premium_tokens_balance: 0)

      entry = described_class.credit(
        user: user,
        amount: 25,
        reason: "purchase:stripe",
        metadata: {"receipt" => "123"}
      )

      expect(entry).to be_persisted
      expect(entry.delta).to eq(25)
      expect(user.reload.premium_tokens_balance).to eq(25)
    end
  end

  describe ".debit" do
    it "raises when spending more than balance" do
      user = create(:user, premium_tokens_balance: 5)

      expect do
        described_class.debit(user: user, amount: 10, reason: "test", actor: user)
      end.to raise_error(described_class::InsufficientBalanceError)
    end
  end
end

require "rails_helper"

RSpec.describe Trades::SettlementService do
  let(:initiator) { create(:user) }
  let(:recipient) { create(:user) }
  let(:trade_session) { create(:trade_session, initiator:, recipient:, status: :confirming, completed_at: nil) }

  before do
    initiator.currency_wallet.update!(gold_balance: 1_000)
    recipient.currency_wallet.update!(gold_balance: 100)
  end

  it "moves gold between wallets" do
    trade_session.trade_items.create!(
      owner: initiator,
      currency_type: "gold",
      currency_amount: 250
    )

    described_class.new(trade_session: trade_session).call

    expect(initiator.currency_wallet.reload.gold_balance).to eq(750)
    expect(recipient.currency_wallet.reload.gold_balance).to eq(350)
  end

  it "moves premium tokens via the ledger" do
    initiator.update!(premium_tokens_balance: 500)
    recipient.update!(premium_tokens_balance: 0)
    initiator.currency_wallet.update!(premium_tokens_balance: 500)
    recipient.currency_wallet.update!(premium_tokens_balance: 0)

    trade_session.trade_items.create!(
      owner: initiator,
      currency_type: "premium_tokens",
      currency_amount: 50
    )

    described_class.new(trade_session: trade_session).call

    expect(initiator.reload.premium_tokens_balance).to eq(450)
    expect(recipient.reload.premium_tokens_balance).to eq(50)
  end
end

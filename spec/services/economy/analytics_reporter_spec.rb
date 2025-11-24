require "rails_helper"

RSpec.describe Economy::AnalyticsReporter do
  it "persists a snapshot and price points" do
    user = create(:user)
    user.currency_wallet.update!(gold_balance: 1_000)
    create(:auction_listing, seller: user, starting_bid: 100, ends_at: 1.hour.from_now)

    session = create(:trade_session, initiator: user, recipient: create(:user), completed_at: Time.current)
    session.trade_items.create!(
      owner: user,
      currency_type: "gold",
      currency_amount: 250
    )
    session.trade_items.create!(
      owner: session.recipient,
      currency_type: "gold",
      currency_amount: 10
    )

    Economy::WalletService.new(wallet: user.currency_wallet).adjust!(
      currency: :gold,
      amount: -50,
      reason: "test",
      metadata: {}
    )

    expect do
      described_class.new.call
    end.to change(EconomicSnapshot, :count).by(1)

    expect(ItemPricePoint.count).to be >= 1
  end
end

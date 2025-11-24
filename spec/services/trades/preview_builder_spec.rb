require "rails_helper"

RSpec.describe Trades::PreviewBuilder do
  it "summarizes contributions for both sides" do
    session = create(:trade_session)
    session.trade_items.create!(
      owner: session.initiator,
      currency_type: "gold",
      currency_amount: 500
    )
    session.trade_items.create!(
      owner: session.recipient,
      currency_type: "gold",
      currency_amount: 100
    )

    preview = described_class.new(trade_session: session).call

    expect(preview.initiator_totals[:gold]).to eq(500)
    expect(preview.recipient_totals[:gold]).to eq(100)
    expect(preview.net_gold).to eq(-400)
    expect(preview.warning?).to be(false)
  end
end

require "rails_helper"

RSpec.describe Marketplace::ListingEngine do
  let(:user) { create(:user) }
  let(:params) do
    {
      item_name: "Steel Helm",
      quantity: 1,
      currency_type: "gold",
      starting_bid: 200,
      ends_at: 1.day.from_now,
      location_key: "capital"
    }
  end

  it "creates an auction listing and charges a listing fee" do
    wallet = user.currency_wallet
    wallet.update!(gold_balance: 1_000)

    listing = described_class.new(user:, params:).create!

    expect(listing).to be_persisted
    expect(listing.tax_rate).to be > 0
    expect(wallet.reload.gold_balance).to be < 1_000
    expect(wallet.currency_transactions.recent.first.reason).to eq("sink.listing_fee")
  end

  it "raises when the seller exceeds the daily listing cap" do
    Economy::ListingCapEnforcer::MAX_LISTINGS_PER_DAY.times do
      create(:auction_listing, seller: user, created_at: 1.hour.ago, status: :active)
    end

    expect do
      described_class.new(user:, params:).create!
    end.to raise_error(Pundit::NotAuthorizedError)
  end
end

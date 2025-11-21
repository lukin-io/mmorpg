require "rails_helper"

RSpec.describe Marketplace::ListingEngine do
  it "creates an auction listing" do
    user = create(:user)
    params = {
      item_name: "Steel Helm",
      quantity: 1,
      currency_type: "gold",
      starting_bid: 200,
      ends_at: 1.day.from_now,
      location_key: "capital"
    }

    listing = described_class.new(user:, params:).create!

    expect(listing).to be_persisted
    expect(listing.tax_rate).to be > 0
  end
end

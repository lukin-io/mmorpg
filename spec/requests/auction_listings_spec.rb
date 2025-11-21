require "rails_helper"

RSpec.describe "AuctionListings", type: :request do
  describe "POST /auction_listings" do
    it "creates a listing" do
      user = create(:user)
      sign_in user, scope: :user

      expect do
        post auction_listings_path, params: {
          auction_listing: {
            item_name: "Gem",
            quantity: 1,
            currency_type: "gold",
            starting_bid: 100,
            ends_at: 1.day.from_now,
            location_key: "capital"
          }
        }
      end.to change(AuctionListing, :count).by(1)
    end
  end
end

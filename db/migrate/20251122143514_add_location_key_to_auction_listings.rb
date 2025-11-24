class AddLocationKeyToAuctionListings < ActiveRecord::Migration[8.1]
  def change
    add_column :auction_listings, :location_key, :string, null: false, default: "capital"
  end
end

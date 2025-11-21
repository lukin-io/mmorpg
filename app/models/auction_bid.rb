# frozen_string_literal: true

class AuctionBid < ApplicationRecord
  belongs_to :auction_listing
  belongs_to :bidder, class_name: "User"

  validates :amount, numericality: {greater_than: 0}
end

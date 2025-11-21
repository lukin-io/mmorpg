# frozen_string_literal: true

class AuctionListing < ApplicationRecord
  enum :status, {
    draft: 0,
    active: 1,
    completed: 2,
    cancelled: 3,
    expired: 4
  }

  belongs_to :seller, class_name: "User"
  has_many :auction_bids, dependent: :destroy

  validates :item_name, :currency_type, :starting_bid, :ends_at, presence: true
  validates :currency_type, inclusion: {in: %w[gold silver premium_tokens]}

  scope :live, -> { active.where("ends_at > ?", Time.current) }

  def highest_bid
    auction_bids.order(amount: :desc).first
  end
end

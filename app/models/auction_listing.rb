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
  belongs_to :required_profession, class_name: "Profession", optional: true
  has_many :auction_bids, dependent: :destroy

  validates :item_name, :currency_type, :starting_bid, :ends_at, presence: true
  validates :currency_type, inclusion: {in: %w[gold silver premium_tokens]}
  validates :required_skill_level, numericality: {greater_than_or_equal_to: 0}
  validates :commission_scope, inclusion: {in: %w[personal guild public]}
  validates :location_key, presence: true

  scope :live, -> { active.where("ends_at > ?", Time.current) }
  scope :commissionable, -> { where.not(required_profession_id: nil) }
  scope :with_item_type, ->(item_type) { where("item_metadata ->> 'item_type' = ?", item_type) }
  scope :with_rarity, ->(rarity) { where("item_metadata ->> 'rarity' = ?", rarity) }
  scope :with_stat_at_least,
    lambda { |stat, minimum|
      where(
        Arel.sql("(item_metadata -> 'stats' ->> ?)::integer >= ?"),
        stat,
        minimum
      )
    }

  def highest_bid
    auction_bids.order(amount: :desc).first
  end

  def profession_gate?
    required_profession.present? && required_skill_level.positive?
  end

  def listing_value
    (starting_bid || 0) * (quantity || 1)
  end

  def demand_score
    MarketDemandSignal
      .where(item_name:)
      .where("recorded_at >= ?", 3.days.ago)
      .sum(:quantity)
  end
end

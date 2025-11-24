# frozen_string_literal: true

class MarketplaceKiosk < ApplicationRecord
  MAX_DURATION_HOURS = 12

  belongs_to :seller, class_name: "User"

  validates :city, :item_name, :price, :expires_at, presence: true
  validates :price, numericality: {greater_than: 0}
  validate :expires_within_cap

  scope :active, -> { where("expires_at > ?", Time.current) }

  before_validation :clamp_expiration

  private

  def clamp_expiration
    return if expires_at.blank?

    self.expires_at = [expires_at, Time.current + MAX_DURATION_HOURS.hours].min
  end

  def expires_within_cap
    return if expires_at.blank?
    return if expires_at <= Time.current + MAX_DURATION_HOURS.hours

    errors.add(:expires_at, "must be within #{MAX_DURATION_HOURS} hours")
  end
end

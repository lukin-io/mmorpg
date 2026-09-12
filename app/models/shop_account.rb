# frozen_string_literal: true

# One authored Shop's independent NV pool. Trade services lock this account
# with its stock and the player's records before committing a settlement.
class ShopAccount < ApplicationRecord
  LOCATION_TYPES = %w[CityHotspot TileBuilding].freeze
  NV_LIMIT = 10_000_000_000

  belongs_to :location, polymorphic: true
  has_many :shop_stocks, dependent: :restrict_with_exception

  validates :location_type, inclusion: {in: LOCATION_TYPES}
  validates :location_id, uniqueness: {scope: :location_type}
  validates :nv_balance, numericality: {greater_than_or_equal_to: 0, less_than: NV_LIMIT}
  validate :location_must_be_shop

  private

  def location_must_be_shop
    return unless LOCATION_TYPES.include?(location_type)

    shop = case location
    when CityHotspot
      location.action_type == "open_feature" && location.action_params.to_h["feature"].in?(%w[shop hospital])
    when TileBuilding
      location.location? && location.location_feature_available?("shop")
    end
    errors.add(:location, "must provide an authored Shop") unless shop
  end
end

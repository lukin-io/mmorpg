# frozen_string_literal: true

class MarketplaceKiosk < ApplicationRecord
  belongs_to :seller, class_name: "User"

  validates :city, :item_name, :price, :expires_at, presence: true
end

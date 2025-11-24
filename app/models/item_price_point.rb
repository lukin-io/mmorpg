# frozen_string_literal: true

# ItemPricePoint records average/median price samples for a specific item and currency.
class ItemPricePoint < ApplicationRecord
  validates :item_name, :currency_type, :sampled_on, presence: true
  validates :average_price, :median_price, :volume, numericality: {greater_than_or_equal_to: 0}

  scope :for_item, ->(name) { where(item_name: name) }
end

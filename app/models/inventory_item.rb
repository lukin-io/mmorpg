# frozen_string_literal: true

# InventoryItem tracks stack counts, equipment state, and enhancement metadata.
class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item_template

  scope :equipped, -> { where(equipped: true) }

  validates :quantity, numericality: {greater_than: 0}
  validates :weight, :enhancement_level, numericality: {greater_than_or_equal_to: 0}
end

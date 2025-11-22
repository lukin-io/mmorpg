# frozen_string_literal: true

# Inventory encapsulates slot + weight capacity per character.
class Inventory < ApplicationRecord
  belongs_to :character
  has_many :inventory_items, dependent: :destroy

  validates :slot_capacity, :weight_capacity, numericality: {greater_than: 0}
  validates :current_weight, numericality: {greater_than_or_equal_to: 0}
end

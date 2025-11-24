# frozen_string_literal: true

# MarketDemandSignal stores supply/demand events (crafting completions, kiosk shortages)
# so the auction house can surface trending items.
class MarketDemandSignal < ApplicationRecord
  SOURCES = %w[crafting trading infirmary manual].freeze

  belongs_to :profession, optional: true
  belongs_to :zone, optional: true

  validates :source, inclusion: {in: SOURCES}
  validates :item_name, presence: true
  validates :quantity, numericality: {greater_than: 0}
  validates :recorded_at, presence: true

  scope :recent, -> { where("recorded_at >= ?", 7.days.ago) }
end

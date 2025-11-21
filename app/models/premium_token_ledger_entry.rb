# frozen_string_literal: true

class PremiumTokenLedgerEntry < ApplicationRecord
  ENTRY_TYPES = {
    purchase: "purchase",
    spend: "spend",
    adjustment: "adjustment"
  }.freeze

  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true

  enum :entry_type, ENTRY_TYPES, suffix: :entry

  validates :entry_type, :delta, :balance_after, presence: true
  validates :delta, numericality: {other_than: 0}
  validates :balance_after, numericality: {greater_than_or_equal_to: 0}

  scope :recent, -> { order(created_at: :desc) }
end

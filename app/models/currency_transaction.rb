# frozen_string_literal: true

class CurrencyTransaction < ApplicationRecord
  belongs_to :currency_wallet

  validates :amount, numericality: {other_than: 0}
  validates :reason, presence: true
  validates :balance_after, numericality: {greater_than_or_equal_to: 0}

  scope :recent, -> { order(created_at: :desc) }
end

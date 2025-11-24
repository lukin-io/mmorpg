# frozen_string_literal: true

class CurrencyTransaction < ApplicationRecord
  CURRENCY_TYPES = %w[gold silver premium_tokens].freeze

  belongs_to :currency_wallet

  validates :currency_type, inclusion: {in: CURRENCY_TYPES}
  validates :amount, numericality: {other_than: 0}
  validates :reason, presence: true
  validates :balance_after, numericality: {greater_than_or_equal_to: 0}

  scope :recent, -> { order(created_at: :desc) }
  scope :for_currency, ->(currency) { where(currency_type: currency) }
end

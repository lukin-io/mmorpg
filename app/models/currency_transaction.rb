# frozen_string_literal: true

class CurrencyTransaction < ApplicationRecord
  belongs_to :currency_wallet

  validates :currency_type, inclusion: {in: %w[gold silver premium_tokens]}
  validates :amount, numericality: {other_than: 0}
  validates :reason, presence: true
end


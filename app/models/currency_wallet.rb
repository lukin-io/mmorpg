# frozen_string_literal: true

class CurrencyWallet < ApplicationRecord
  belongs_to :user
  has_many :currency_transactions, dependent: :destroy

  validates :user_id, uniqueness: true

  def adjust!(currency:, amount:)
    case currency.to_sym
    when :gold
      increment!(:gold_balance, amount)
    when :silver
      increment!(:silver_balance, amount)
    when :premium_tokens
      increment!(:premium_tokens_balance, amount)
    else
      raise ArgumentError, "Unknown currency #{currency}"
    end
  end
end

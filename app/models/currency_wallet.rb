# frozen_string_literal: true

class CurrencyWallet < ApplicationRecord
  belongs_to :user
  has_many :currency_transactions, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :nv_balance, numericality: {greater_than_or_equal_to: 0}

  def adjust!(amount:, reason: "manual.adjustment", metadata: {})
    Economy::WalletService.new(wallet: self).adjust!(
      amount: amount,
      reason: reason,
      metadata: metadata
    )
  end

  def balance
    nv_balance
  end
end

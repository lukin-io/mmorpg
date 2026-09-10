# frozen_string_literal: true

class CurrencyWallet < ApplicationRecord
  # Exclusive limit of the existing decimal(12, 2) storage, not a gameplay cap.
  NV_STORAGE_LIMIT = 10_000_000_000

  belongs_to :user
  has_many :currency_transactions, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :nv_balance, numericality: {greater_than_or_equal_to: 0, less_than: NV_STORAGE_LIMIT}

  def adjust!(amount:, reason:, metadata: {})
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

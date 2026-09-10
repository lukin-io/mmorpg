# frozen_string_literal: true

class CurrencyTransaction < ApplicationRecord
  SHOP_RECEIPT_REASONS = %w[shop.purchase shop.sale].freeze

  belongs_to :currency_wallet
  belongs_to :shop_offer, class_name: "WorldActionOffer", optional: true
  belongs_to :shop_account, optional: true

  validates :amount, numericality: {other_than: 0,
                                  greater_than: -CurrencyWallet::NV_STORAGE_LIMIT,
                                  less_than: CurrencyWallet::NV_STORAGE_LIMIT}
  validates :reason, presence: true
  validates :balance_after, numericality: {greater_than_or_equal_to: 0, less_than: CurrencyWallet::NV_STORAGE_LIMIT}

  scope :recent, -> { order(created_at: :desc) }

  # Ordinary callers receive a clear error; the database also rejects raw SQL
  # updates/deletes and changing the reason to escape receipt retention.
  def readonly?
    super || (persisted? && [reason_in_database, reason].any? { |value| SHOP_RECEIPT_REASONS.include?(value) })
  end
end

# frozen_string_literal: true

# P2P NV↔VM exchange offers (real-money cashout stays outside this table).
class CurrencyExchangeOffer < ApplicationRecord
  belongs_to :seller, class_name: "User"

  validates :give_currency, :want_currency, inclusion: {in: %w[nv vm]}
  validates :give_amount, :want_amount, numericality: {greater_than: 0}
  validates :status, inclusion: {in: %w[open filled cancelled]}
  validate :currencies_differ

  scope :open, -> { where(status: "open") }

  private

  def currencies_differ
    errors.add(:want_currency, I18n.t("game.trade_hub.exchange_same_currency")) if give_currency == want_currency
  end
end

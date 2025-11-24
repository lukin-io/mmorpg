# frozen_string_literal: true

class CurrencyWallet < ApplicationRecord
  CURRENCIES = %i[gold silver premium_tokens].freeze

  belongs_to :user
  has_many :currency_transactions, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :gold_balance, :silver_balance, :premium_tokens_balance,
    numericality: {greater_than_or_equal_to: 0}
  validates :gold_soft_cap, :silver_soft_cap, :premium_tokens_soft_cap,
    numericality: {greater_than: 0}

  def adjust!(currency:, amount:, reason: "manual.adjustment", metadata: {})
    Economy::WalletService.new(wallet: self).adjust!(
      currency: currency,
      amount: amount,
      reason: reason,
      metadata: metadata
    )
  end

  def balance_for(currency)
    assert_currency!(currency)
    public_send("#{currency}_balance")
  end

  def soft_cap_for(currency)
    assert_currency!(currency)
    public_send("#{currency}_soft_cap")
  end

  def sink_totals_for(currency)
    sink_totals.fetch(currency.to_s, 0)
  end

  def record_sink_total!(currency:, amount:)
    assert_currency!(currency)
    updated_totals = sink_totals.merge(
      currency.to_s => sink_totals_for(currency) + amount
    )
    update!(sink_totals: updated_totals)
  end

  private

  def assert_currency!(currency)
    return if CURRENCIES.include?(currency.to_sym)

    raise ArgumentError, "Unknown currency #{currency}"
  end
end

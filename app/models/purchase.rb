# frozen_string_literal: true

class Purchase < ApplicationRecord
  belongs_to :user

  enum :status, {
    pending: "pending",
    succeeded: "succeeded",
    failed: "failed",
    refunded: "refunded"
  }, suffix: true

  validates :provider, :external_id, :status, :currency, presence: true
  validates :external_id, uniqueness: true
  validates :amount_cents, numericality: {greater_than: 0}

  after_update_commit :credit_premium_tokens, if: :succeeded_status?

  def token_amount
    metadata.fetch("token_amount", 0).to_i
  end

  private

  def credit_premium_tokens
    return unless saved_change_to_status?
    return if token_amount <= 0

    Payments::PremiumTokenLedger.credit(
      user: user,
      amount: token_amount,
      reason: "purchase:#{provider}",
      reference: self,
      metadata: metadata
    )
  end
end

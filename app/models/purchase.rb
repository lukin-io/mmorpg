# frozen_string_literal: true

class Purchase < ApplicationRecord
  belongs_to :user

  enum status: {
    pending: "pending",
    succeeded: "succeeded",
    failed: "failed",
    refunded: "refunded"
  }, _suffix: :status

  validates :provider, :external_id, :status, :currency, presence: true
  validates :external_id, uniqueness: true
  validates :amount_cents, numericality: {greater_than: 0}
end

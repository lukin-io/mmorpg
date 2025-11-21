# frozen_string_literal: true

class TradeSession < ApplicationRecord
  enum :status, {
    pending: 0,
    confirming: 1,
    completed: 2,
    cancelled: 3,
    expired: 4
  }

  belongs_to :initiator, class_name: "User"
  belongs_to :recipient, class_name: "User"

  has_many :trade_items, dependent: :destroy

  validates :expires_at, presence: true

  scope :active, -> { where(status: [:pending, :confirming]).where("expires_at > ?", Time.current) }
end

# frozen_string_literal: true

# EconomyAlert flags suspicious trades or market manipulation for moderation review.
class EconomyAlert < ApplicationRecord
  STATUSES = {
    open: "open",
    acknowledged: "acknowledged",
    resolved: "resolved"
  }.freeze

  belongs_to :trade_session, optional: true

  enum :status, STATUSES

  validates :alert_type, presence: true
  validates :flagged_at, presence: true
end

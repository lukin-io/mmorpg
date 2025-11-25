# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  enum :status, {
    pending: "pending",
    delivered: "delivered",
    failed: "failed"
  }

  belongs_to :webhook_endpoint

  validates :event_type, presence: true
end

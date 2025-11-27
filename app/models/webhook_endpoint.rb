# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  belongs_to :integration_token
  has_many :webhook_events, dependent: :destroy

  scope :active, -> { where(enabled: true) }
  scope :subscribed_to, ->(event_type) { where("? = ANY(event_types)", event_type) }

  validates :name, :target_url, :secret, presence: true
  validate :target_url_must_be_http

  private

  def target_url_must_be_http
    uri = URI.parse(target_url)
    return if Webhooks::UrlSafety.safe?(uri)

    errors.add(:target_url, "must be HTTP/HTTPS and point to a public host")
  rescue URI::InvalidURIError
    errors.add(:target_url, "is invalid")
  end
end

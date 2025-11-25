# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  belongs_to :integration_token
  has_many :webhook_events, dependent: :destroy

  validates :name, :target_url, :secret, presence: true
  validate :target_url_must_be_http

  private

  def target_url_must_be_http
    uri = URI.parse(target_url)
    return if %w[http https].include?(uri.scheme)

    errors.add(:target_url, "must be HTTP or HTTPS")
  rescue URI::InvalidURIError
    errors.add(:target_url, "is invalid")
  end
end

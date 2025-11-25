# frozen_string_literal: true

require "net/http"
require "uri"

module Webhooks
  class DeliverJob < ApplicationJob
    queue_as :default

    def perform(event_id)
      event = WebhookEvent.find(event_id)
      endpoint = event.webhook_endpoint

      uri = URI.parse(endpoint.target_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["X-Webhook-Event"] = event.event_type
      request["X-Webhook-Signature"] = signature(endpoint.secret, event.payload)
      request.body = event.payload.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        event.update!(status: :delivered, last_attempted_at: Time.current, delivery_attempts: event.delivery_attempts + 1)
        endpoint.update!(last_success_at: Time.current)
      else
        event.update!(status: :failed, last_attempted_at: Time.current, delivery_attempts: event.delivery_attempts + 1)
        endpoint.update!(last_error_at: Time.current)
      end
    end

    private

    def signature(secret, payload)
      OpenSSL::HMAC.hexdigest("SHA256", secret, payload.to_json)
    end
  end
end

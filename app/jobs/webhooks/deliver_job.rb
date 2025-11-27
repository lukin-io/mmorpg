# frozen_string_literal: true

module Webhooks
  # Background job for webhook delivery.
  #
  # Handles the actual HTTP request to webhook endpoints.
  #
  class DeliverJob < ApplicationJob
    queue_as :webhooks
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(event_id, endpoint_id)
      event = WebhookEvent.find_by(id: event_id)
      endpoint = WebhookEndpoint.find_by(id: endpoint_id)

      return unless event && endpoint

      dispatcher = Webhooks::EventDispatcher.new(event: event, endpoint: endpoint)
      dispatcher.deliver!
    end
  end
end

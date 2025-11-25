# frozen_string_literal: true

module Webhooks
  # EventDispatcher enqueues webhook deliveries for fan-made tool integrations.
  #
  # Usage:
  #   Webhooks::EventDispatcher.new(event_type: "achievement.unlocked", payload: {...}).call
  class EventDispatcher
    def initialize(event_type:, payload:)
      @event_type = event_type
      @payload = payload
    end

    def call
      WebhookEndpoint.where(enabled: true).where("? = ANY(event_types)", event_type.to_s).find_each do |endpoint|
        event = endpoint.webhook_events.create!(
          event_type: event_type,
          payload: payload,
          status: :pending
        )
        Webhooks::DeliverJob.perform_later(event.id)
      end
    end

    private

    attr_reader :event_type, :payload
  end
end

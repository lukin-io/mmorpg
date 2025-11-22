# frozen_string_literal: true

require "net/http"
require "uri"

module Moderation
  # WebhookDispatcher posts urgent moderation alerts to Discord/Telegram endpoints.
  # Usage:
  #   Moderation::WebhookDispatcher.post!(message: "Alert", severity: "critical", context: {...})
  # Returns:
  #   true if at least one webhook accepted, false otherwise.
  class WebhookDispatcher
    HEADERS = {"Content-Type" => "application/json"}.freeze

    def self.post!(message:, severity:, context: {})
      new(message:, severity:, context:).post!
    end

    def initialize(message:, severity:, context:)
      @message = message
      @severity = severity
      @context = context
    end

    def post!
      webhooks.map do |url|
        next if url.blank?

        post_to(url)
      rescue => e
        Rails.logger.error("Moderation webhook failed for #{url}: #{e.message}")
        nil
      end.compact.any?
    end

    private

    attr_reader :message, :severity, :context

    def webhooks
      [
        ENV["MODERATION_DISCORD_WEBHOOK_URL"],
        ENV["MODERATION_TELEGRAM_WEBHOOK_URL"]
      ]
    end

    def payload
      {
        text: "[#{severity.upcase}] #{message}",
        severity: severity,
        context: context
      }
    end

    def post_to(url)
      if defined?(Faraday)
        Faraday.post(url, payload.to_json, HEADERS)
      else
        uri = URI.parse(url)
        Net::HTTP.post(uri, payload.to_json, HEADERS)
      end
    end
  end
end

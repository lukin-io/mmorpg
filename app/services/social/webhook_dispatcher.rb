# frozen_string_literal: true

require "net/http"
require "uri"

module Social
  # WebhookDispatcher publishes social achievements (guild perks, arena wins) to Discord/Telegram.
  # Usage:
  #   Social::WebhookDispatcher.new(event: "guild_level_up", payload: {...}).post!
  class WebhookDispatcher
    HEADERS = {"Content-Type" => "application/json"}.freeze

    def initialize(event:, payload:, http_adapter: default_http_adapter)
      @event = event
      @payload = payload
      @http_adapter = http_adapter
    end

    def post!
      endpoints.map do |url|
        next if url.blank?

        deliver(url)
      rescue => e
        Rails.logger.error("Social webhook failed for #{url}: #{e.message}")
        nil
      end.compact.any?
    end

    private

    attr_reader :event, :payload, :http_adapter

    def endpoints
      [
        ENV["SOCIAL_DISCORD_WEBHOOK_URL"],
        ENV["SOCIAL_TELEGRAM_WEBHOOK_URL"]
      ]
    end

    def deliver(url)
      http_adapter.post(url, body_for(url), HEADERS)
    end

    def body_for(_url)
      {
        event: event,
        payload: payload,
        occurred_at: Time.current.iso8601
      }.to_json
    end

    def default_http_adapter
      if defined?(Faraday)
        Faraday
      else
        SimpleHttpAdapter
      end
    end

    # Lightweight adapter so we don't rely on Faraday in tests.
    module SimpleHttpAdapter
      module_function

      def post(url, body, headers)
        uri = URI.parse(url)
        Net::HTTP.post(uri, body, headers)
      end
    end
  end
end

# frozen_string_literal: true

require "net/http"
require "uri"

module Clans
  # DiscordWebhookPublisher pushes clan announcements to the clan-configured
  # Discord webhook URL with a consistent payload.
  #
  # Usage:
  #   Clans::DiscordWebhookPublisher.new(clan:, post:).broadcast!
  class DiscordWebhookPublisher
    HEADERS = {"Content-Type" => "application/json"}.freeze

    def initialize(clan:, post:, http_adapter: default_http_adapter)
      @clan = clan
      @post = post
      @http_adapter = http_adapter
    end

    def broadcast!
      return false if clan.discord_webhook_url.blank?

      http_adapter.post(clan.discord_webhook_url, body, HEADERS)
      post.update!(broadcasted_at: Time.current)
      true
    rescue => e
      Rails.logger.error("Clan webhook broadcast failed for clan #{clan.id}: #{e.message}")
      false
    end

    private

    attr_reader :clan, :post, :http_adapter

    def body
      {
        title: post.title,
        body: post.body,
        published_at: post.published_at.iso8601,
        clan: {
          id: clan.id,
          name: clan.name,
          level: clan.level,
          leader: clan.leader.profile_name
        }
      }.to_json
    end

    def default_http_adapter
      if defined?(Faraday)
        Faraday
      else
        SimpleHttpAdapter
      end
    end

    module SimpleHttpAdapter
      module_function

      def post(url, body, headers)
        uri = URI.parse(url)
        Net::HTTP.post(uri, body, headers)
      end
    end
  end
end

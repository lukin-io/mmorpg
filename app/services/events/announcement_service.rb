# frozen_string_literal: true

module Events
  # Broadcasts event announcements through Turbo Streams and optional webhooks.
  #
  # Usage:
  #   Events::AnnouncementService.new(event).broadcast!("Seasonal event starting soon!")
  class AnnouncementService
    def initialize(event, broadcaster: ActionCable.server, webhook_url: ENV["EVENTS_WEBHOOK_URL"])
      @event = event
      @broadcaster = broadcaster
      @webhook_url = webhook_url
    end

    def broadcast!(message)
      payload = {event_id: event.id, message:, occurred_at: Time.current.iso8601}
      broadcaster.broadcast("events:announcements", payload)
      post_webhook(payload) if webhook_url.present?
    end

    private

    attr_reader :event, :broadcaster, :webhook_url

    def post_webhook(payload)
      uri = URI.parse(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      request = Net::HTTP::Post.new(uri.request_uri, {"Content-Type" => "application/json"})
      request.body = payload.to_json
      http.request(request)
    rescue StandardError => e
      Rails.logger.warn("Event webhook failed: #{e.message}")
    end
  end
end


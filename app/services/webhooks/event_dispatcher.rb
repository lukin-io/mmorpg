# frozen_string_literal: true

module Webhooks
  # Dispatches webhook events to registered endpoints.
  #
  # Handles event queuing, delivery, and retry logic.
  #
  # @example Dispatch an event
  #   Webhooks::EventDispatcher.dispatch(
  #     event_type: "player.level_up",
  #     payload: { player_id: 1, new_level: 10 }
  #   )
  #
  class EventDispatcher
    EVENT_TYPES = %w[
      player.level_up
      player.achievement
      player.death
      achievement.unlocked
      arena.match_complete
      dungeon.complete
      auction.sale
      clan.war_declared
      clan.war_result
    ].freeze

    class << self
      # Dispatch an event to all subscribed endpoints
      def dispatch(event_type:, payload:, source: nil)
        return unless EVENT_TYPES.include?(event_type)

        endpoints = WebhookEndpoint.active.subscribed_to(event_type)
        return if endpoints.empty?

        event = create_event(event_type, payload, source)

        endpoints.find_each do |endpoint|
          Webhooks::DeliverJob.perform_later(event.id, endpoint.id)
        end

        event
      end

      # Create and persist webhook event
      def create_event(event_type, payload, source)
        WebhookEvent.create!(
          event_type: event_type,
          payload: payload.to_json,
          source: source || "system",
          status: :pending,
          attempts: 0
        )
      end
    end

    attr_reader :event, :endpoint

    def initialize(event:, endpoint:)
      @event = event
      @endpoint = endpoint
    end

    # Deliver the webhook event
    def deliver!
      return false unless event.pending? || event.failed?
      return false unless endpoint.active?

      begin
        response = send_request
        handle_response(response)
      rescue => e
        handle_error(e)
      end
    end

    private

    def send_request
      uri = URI.parse(endpoint.url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Webhook-Event"] = event.event_type
      request["X-Webhook-Signature"] = generate_signature
      request["X-Webhook-Timestamp"] = Time.current.to_i.to_s

      request.body = event.payload

      http.request(request)
    end

    def generate_signature
      timestamp = Time.current.to_i
      data = "#{timestamp}.#{event.payload}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, data)
      "sha256=#{signature}"
    end

    def handle_response(response)
      event.increment!(:attempts)

      if response.code.to_i.between?(200, 299)
        event.update!(
          status: :delivered,
          delivered_at: Time.current,
          last_response_code: response.code.to_i
        )
        true
      else
        event.update!(
          status: :failed,
          last_response_code: response.code.to_i,
          last_error: response.body.truncate(500)
        )
        schedule_retry if event.attempts < 5
        false
      end
    end

    def handle_error(error)
      event.increment!(:attempts)
      event.update!(
        status: :failed,
        last_error: error.message.truncate(500)
      )
      schedule_retry if event.attempts < 5
      false
    end

    def schedule_retry
      delay = [30, 60, 300, 1800, 3600][event.attempts - 1] || 3600
      Webhooks::DeliverJob.set(wait: delay.seconds).perform_later(event.id, endpoint.id)
    end
  end
end

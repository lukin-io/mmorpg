# frozen_string_literal: true

module Arena
  # Best-effort delivery boundary for Arena presentation events.
  #
  # Persisted match/application state is authoritative. A temporary Action
  # Cable or Redis outage must not roll back that state or turn a successful
  # gameplay request into an HTTP 500 response.
  class RealtimePublisher
    def initialize(server: ActionCable.server, logger: Rails.logger)
      @server = server
      @logger = logger
    end

    def publish(channel:, payload:)
      @server.broadcast(channel, payload)
      true
    rescue StandardError => error
      @logger.warn(
        "[Arena::RealtimePublisher] delivery_failed " \
        "channel=#{channel.inspect} type=#{payload[:type].inspect} error=#{error.class}"
      )
      false
    end
  end
end

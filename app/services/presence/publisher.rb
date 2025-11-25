# frozen_string_literal: true

module Presence
  class Publisher
    CHANNEL = "presence:global"

    def initialize(broadcaster: ActionCable.server)
      @broadcaster = broadcaster
    end

    def online!(user:, session:)
      broadcast(user:, session:, status: "online")
    end

    def idle!(user:, session:)
      broadcast(user:, session:, status: "idle")
    end

    def busy!(user:, session:)
      broadcast(user:, session:, status: "busy")
    end

    def offline!(user:, session:)
      broadcast(user:, session:, status: "offline")
    end

    private

    attr_reader :broadcaster

    def broadcast(user:, session:, status:)
      payload = {
        user_id: user.id,
        status: status,
        session_id: session.id,
        device_id: session.device_id,
        occurred_at: Time.current.iso8601,
        zone_name: session.current_zone_name,
        location: session.current_location_label,
        last_activity_at: session.last_activity_at&.iso8601
      }
      broadcaster.broadcast(CHANNEL, payload)
    end
  end
end

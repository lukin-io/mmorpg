# frozen_string_literal: true

module Arena
  # SpectatorBroadcaster emits Turbo-compatible payloads for arena spectators.
  # Usage:
  #   Arena::SpectatorBroadcaster.new(match: match).broadcast!(event: "round", payload: {...})
  class SpectatorBroadcaster
    def initialize(match:, broadcaster: ActionCable.server)
      @match = match
      @broadcaster = broadcaster
    end

    def broadcast!(event:, payload:)
      broadcaster.broadcast(
        match.broadcast_channel,
        {
          type: event,
          match_id: match.id,
          payload:
        }
      )
    end

    private

    attr_reader :match, :broadcaster
  end
end

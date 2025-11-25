# frozen_string_literal: true

module Presence
  # FriendBroadcaster pushes presence snapshots for an entire friend list.
  # Usage:
  #   Presence::FriendBroadcaster.new.broadcast_for(user)
  # Returns:
  #   Broadcast payload hash for debugging.
  class FriendBroadcaster
    CHANNEL_PREFIX = "presence:friends:"

    def initialize(broadcaster: ActionCable.server)
      @broadcaster = broadcaster
    end

    def broadcast_for(user)
      payload = {
        type: "friend_presence",
        friends: snapshot_for(user)
      }

      broadcaster.broadcast(channel_for(user), payload)
      payload
    end

    def snapshot_for(user)
      serialize_friends(user)
    end

    def channel_for(user)
      "#{CHANNEL_PREFIX}#{user.id}"
    end

    private

    attr_reader :broadcaster

    def serialize_friends(user)
      user.friends.map do |friend|
        session = friend.user_sessions.active.order(updated_at: :desc).first
        snapshot = session&.presence_snapshot || {}

        {
          id: friend.id,
          profile_name: friend.profile_name,
          status: normalize_status(snapshot[:status]),
          zone: snapshot[:zone_name],
          location: snapshot[:location],
          last_activity_at: (snapshot[:last_activity_at] || friend.last_seen_at)&.iso8601,
          character_name: snapshot[:character_name]
        }
      end
    end

    def normalize_status(status)
      return "offline" if status.blank?

      return "afk" if status == "idle"

      status
    end
  end
end

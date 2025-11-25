# frozen_string_literal: true

class SessionPresenceJob < ApplicationJob
  queue_as :presence

  def perform(user_id:, device_id:, state:, timestamp: Time.current)
    user = User.find_by(id: user_id)
    return unless user

    session = user.user_sessions.find_by(device_id: device_id)
    return unless session

    publisher = Presence::Publisher.new

    case state
    when "active", "online"
      session.mark_active!(timestamp: timestamp)
      user.update!(last_seen_at: timestamp)
      publisher.online!(user: user, session: session)
    when "idle"
      session.mark_idle!(timestamp: timestamp)
      user.update!(last_seen_at: timestamp)
      publisher.idle!(user: user, session: session)
    when "busy"
      session.mark_busy!(timestamp: timestamp)
      user.update!(last_seen_at: timestamp)
      publisher.busy!(user: user, session: session)
    when "offline"
      session.mark_offline!(timestamp: timestamp)
      publisher.offline!(user: user, session: session)
    end

    Presence::FriendBroadcaster.new.broadcast_for(user)
  end
end

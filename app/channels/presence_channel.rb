# frozen_string_literal: true

class PresenceChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user

    stream_from Presence::Publisher::CHANNEL
    stream_from friend_channel_name

    Presence::FriendBroadcaster.new.broadcast_for(current_user)
  end

  private

  def friend_channel_name
    "#{Presence::FriendBroadcaster::CHANNEL_PREFIX}#{current_user.id}"
  end
end

# frozen_string_literal: true

# Presence channel for tracking online users
# Broadcasts user online/offline status and provides online player list
#
# @example Subscribe to presence
#   consumer.subscriptions.create({ channel: "PresenceChannel" })
#
# @example Subscribe to zone-specific presence
#   consumer.subscriptions.create({ channel: "PresenceChannel", zone_id: 1 })
#
class PresenceChannel < ApplicationCable::Channel
  GLOBAL_CHANNEL = "presence:global"
  ONLINE_PLAYERS_CHANNEL = "presence:online"

  def subscribed
    reject unless current_user

    stream_from Presence::Publisher::CHANNEL
    stream_from friend_channel_name
    stream_from GLOBAL_CHANNEL
    stream_from ONLINE_PLAYERS_CHANNEL

    # Subscribe to zone-specific presence if provided
    if params[:zone_id].present?
      @zone = Zone.find_by(id: params[:zone_id])
      stream_from "presence:zone:#{@zone.id}" if @zone
    end

    # Mark user as online and broadcast
    mark_online
    Presence::FriendBroadcaster.new.broadcast_for(current_user)
  end

  def unsubscribed
    stop_all_streams
    mark_offline
  end

  # Request list of online players
  def request_online_players(data = {})
    zone_id = data["zone_id"]
    limit = [data["limit"].to_i, 100].min
    limit = 50 if limit <= 0

    players = fetch_online_players(zone_id, limit)

    transmit({
      type: "online_players",
      count: players.count,
      players: players.map { |p| format_player(p) }
    })
  end

  # Request online count only
  def request_online_count
    count = UserSession.online.count

    transmit({
      type: "online_count",
      count: count
    })
  end

  # Ping to keep presence active
  def ping
    mark_online
    transmit({type: "pong", timestamp: Time.current.iso8601})
  end

  # Update zone presence (when player moves)
  def update_zone(data)
    new_zone_id = data["zone_id"]
    return unless new_zone_id

    old_zone = @zone
    @zone = Zone.find_by(id: new_zone_id)

    if old_zone && @zone != old_zone
      stop_stream_from("presence:zone:#{old_zone.id}")
      broadcast_zone_leave(old_zone)
    end

    if @zone
      stream_from "presence:zone:#{@zone.id}"
      broadcast_zone_enter(@zone)
    end
  end

  private

  def friend_channel_name
    "#{Presence::FriendBroadcaster::CHANNEL_PREFIX}#{current_user.id}"
  end

  def mark_online
    session = current_user.current_session
    session&.mark_online! if session.respond_to?(:mark_online!)

    # Broadcast to online players channel
    broadcast_status("online")
  end

  def mark_offline
    session = current_user.current_session
    session&.mark_offline!(timestamp: Time.current) if session.respond_to?(:mark_offline!)

    # Broadcast to online players channel
    broadcast_status("offline")
  end

  def broadcast_status(status)
    return unless current_user.character

    ActionCable.server.broadcast(ONLINE_PLAYERS_CHANNEL, {
      type: "player_status",
      status: status,
      player: format_player(current_user)
    })
  end

  def broadcast_zone_enter(zone)
    return unless current_user.character

    ActionCable.server.broadcast("presence:zone:#{zone.id}", {
      type: "player_entered",
      player: format_player(current_user)
    })
  end

  def broadcast_zone_leave(zone)
    return unless current_user.character

    ActionCable.server.broadcast("presence:zone:#{zone.id}", {
      type: "player_left",
      player: {
        user_id: current_user.id,
        character_name: current_user.character&.name
      }
    })
  end

  def fetch_online_players(zone_id, limit)
    sessions = UserSession.online.includes(user: :characters).limit(limit)

    if zone_id.present?
      # Filter by zone - requires character positions
      sessions = sessions.joins(user: {characters: :position})
        .where(positions: {zone_id: zone_id})
    end

    sessions.map(&:user).compact
  end

  def format_player(user)
    character = user.character

    {
      user_id: user.id,
      character_id: character&.id,
      character_name: character&.name || user.profile_name,
      level: character&.level,
      faction: character&.faction_alignment,
      title: character&.current_title,
      status: user_status(user),
      zone_id: character&.position&.zone_id,
      zone_name: character&.position&.zone&.name
    }
  end

  def user_status(user)
    session = user.current_session
    return "offline" unless session&.online?

    if session.away?
      "away"
    elsif session.busy?
      "busy"
    else
      "online"
    end
  end
end

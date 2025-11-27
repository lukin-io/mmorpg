# frozen_string_literal: true

# Global arena updates (applications, room changes)
# Clients subscribe to specific rooms or the lobby
#
# @example Subscribe to arena lobby
#   consumer.subscriptions.create({ channel: "ArenaChannel" })
#
# @example Subscribe to a specific room
#   consumer.subscriptions.create({ channel: "ArenaChannel", room_id: 1 })
#
class ArenaChannel < ApplicationCable::Channel
  def subscribed
    stream_from "arena:lobby"

    if params[:room_id].present?
      @room = ArenaRoom.find_by(id: params[:room_id])
      if @room
        stream_from "arena:room:#{@room.id}"
      else
        reject
      end
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Request current room state
  def request_room_state
    return unless @room

    transmit({
      type: "room_state",
      room: {
        id: @room.id,
        name: @room.name,
        level_range: "#{@room.level_min}-#{@room.level_max}",
        active_matches: @room.current_match_count,
        open_applications: @room.open_application_count
      },
      applications: @room.arena_applications.open.map do |app|
        {
          id: app.id,
          fight_type: app.fight_type,
          fight_kind: app.fight_kind,
          applicant_name: app.applicant.name,
          applicant_level: app.applicant.level,
          expires_in: app.time_until_expiration
        }
      end
    })
  end
end

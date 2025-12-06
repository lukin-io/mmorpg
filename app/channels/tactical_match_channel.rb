# frozen_string_literal: true

# ActionCable channel for real-time tactical match updates.
#
# Broadcasts grid changes, turn changes, and combat log entries.
#
# @example Subscribe to a tactical match
#   consumer.subscriptions.create({ channel: "TacticalMatchChannel", match_id: 1 })
#
class TacticalMatchChannel < ApplicationCable::Channel
  def subscribed
    @tactical_match = TacticalMatch.find_by(id: params[:match_id])
    reject unless @tactical_match && can_view_match?

    stream_from "tactical_match:#{@tactical_match.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def can_view_match?
    character = current_user.characters.first
    return true if @tactical_match.creator_id == character&.id
    return true if @tactical_match.opponent_id == character&.id

    # Allow spectators for completed matches
    @tactical_match.completed? || @tactical_match.forfeited?
  end
end

# frozen_string_literal: true

# Per-match combat updates channel
# Broadcasts HP updates, combat log, countdown, and results
#
# @example Subscribe to a match
#   consumer.subscriptions.create({ channel: "ArenaMatchChannel", match_id: 123 })
#
class ArenaMatchChannel < ApplicationCable::Channel
  def subscribed
    @match = ArenaMatch.find_by(id: params[:match_id])

    unless @match
      reject
      return
    end

    # Allow participants and spectators
    stream_from @match.broadcast_channel

    # If spectating via code, also stream spectator channel
    if params[:spectator_code] == @match.spectator_code
      stream_from "arena:spectate:#{@match.spectator_code}"
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Submit a combat action (only for participants)
  #
  # @param data [Hash] action data
  def submit_action(data)
    return unless @match&.live?
    return unless current_user_is_participant?

    character = current_character
    return unless character

    # Process the combat action
    Arena::CombatProcessor.new(@match).process_action(
      character: character,
      action_type: data["action_type"],
      target_id: data["target_id"],
      skill_id: data["skill_id"]
    )
  end

  # Request current match state
  def request_match_state
    return unless @match

    transmit({
      type: "match_state",
      match_id: @match.id,
      status: @match.status,
      started_at: @match.started_at&.iso8601,
      duration: @match.duration,
      participants: @match.arena_participations.includes(:character).map do |p|
        {
          character_id: p.character_id,
          character_name: p.character.name,
          team: p.team,
          current_hp: p.character.current_hp,
          max_hp: p.character.max_hp,
          current_mp: p.character.current_mp,
          max_mp: p.character.max_mp,
          is_dead: p.character.current_hp <= 0
        }
      end
    })
  end

  private

  def current_user_is_participant?
    @match.arena_participations.exists?(user: current_user)
  end

  def current_character
    @match.arena_participations.find_by(user: current_user)&.character
  end
end

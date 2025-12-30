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
  #   - action_type [String] "attack", "defend", "skill", "flee"
  #   - target_id [Integer, nil] target character/NPC ID
  #   - skill_id [Integer, nil] skill ID for skill actions
  def submit_action(data)
    return unless @match&.live?
    return unless current_user_is_participant?

    character = current_character
    return unless character

    processor = Arena::CombatProcessor.new(@match)

    # Build params hash for the action
    action_params = {}
    action_params[:target] = find_target(data["target_id"]) if data["target_id"].present?
    action_params[:skill_id] = data["skill_id"] if data["skill_id"].present?

    # Process the combat action (positional: character, action_type, **params)
    result = processor.process_action(
      character,
      data["action_type"].to_sym,
      **action_params
    )

    # Transmit result back to the user who submitted the action
    transmit({
      type: "action_result",
      success: result.success?,
      error: result.error,
      data: result.data
    })
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
      participants: build_participants_data
    })
  end

  private

  def current_user_is_participant?
    @match.arena_participations.exists?(user: current_user)
  end

  def current_character
    @match.arena_participations.find_by(user: current_user)&.character
  end

  def find_target(target_id)
    return nil unless target_id

    # Check if target is a character
    participation = @match.arena_participations.find_by(character_id: target_id)
    return participation.character if participation&.character

    # Check if target is an NPC (format: "npc-123")
    if target_id.to_s.start_with?("npc-")
      npc_id = target_id.to_s.sub("npc-", "").to_i
      return @match.arena_participations.find_by(npc_template_id: npc_id)
    end

    nil
  end

  def build_participants_data
    @match.arena_participations.includes(:character, :npc_template).map do |p|
      if p.npc?
        npc = p.npc_template
        {
          id: "npc-#{npc.id}",
          name: npc.name,
          level: npc.level,
          team: p.team,
          current_hp: p.current_hp,
          max_hp: p.max_hp,
          current_mp: 0,
          max_mp: 0,
          is_npc: true,
          is_dead: p.current_hp <= 0
        }
      else
        char = p.character
        {
          character_id: char.id,
          character_name: char.name,
          team: p.team,
          level: char.level,
          current_hp: char.current_hp,
          max_hp: char.max_hp,
          current_mp: char.current_mp,
          max_mp: char.max_mp,
          is_npc: false,
          is_dead: char.current_hp <= 0
        }
      end
    end
  end
end

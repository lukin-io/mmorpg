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

    stream_from @match.broadcast_channel
  end

  def unsubscribed
    stop_all_streams
  end

  # Submit a combat action (only for participants)
  #
  # @param data [Hash] action data
  #   - action_type [String] "turn" or "surrender"
  #   - target_id [Integer, nil] target character/NPC ID
  #   - attacks [Array<Hash>] complete attack selections
  #   - blocks [Array<Hash>] complete block selection
  #   - skills [Array<Hash>] complete skill selections
  def submit_action(data)
    return unless @match&.reload&.live?
    return unless current_user_is_participant?

    character = current_character
    return unless character

    processor = Arena::CombatProcessor.new(@match)

    # Build params hash for the action
    action_params = {}
    action_params[:target] = find_target(data["target_id"]) if data["target_id"].present?
    action_params[:attacks] = data["attacks"] if data["attacks"].present?
    action_params[:blocks] = data["blocks"] if data["blocks"].present?
    action_params[:skills] = data["skills"] if data["skills"].present?

    result = processor.process_player_intent(
      character,
      data["action_type"],
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

    @match.reload

    transmit({
      type: "match_state",
      match_id: @match.id,
      status: @match.status,
      started_at: @match.started_at&.iso8601,
      duration: @match.duration,
      current_turn_number: @match.current_turn_number,
      current_user_waiting: current_user_waiting?,
      participants: build_participants_data,
      current_user_combat: current_user_combat_data
    })
  end

  private

  def current_user_is_participant?
    @match.arena_participations.exists?(user: current_user)
  end

  def current_character
    @match.arena_participations.find_by(user: current_user)&.character
  end

  def current_user_participation
    @match.arena_participations.find_by(user: current_user)
  end

  def find_target(target_id)
    return nil unless target_id

    # Check if target is a character
    participation = @match.arena_participations.find_by(character_id: target_id)
    return participation.character if participation&.character

    if target_id.to_s.start_with?("npc-participation-")
      participation_id = target_id.to_s.delete_prefix("npc-participation-").to_i
      return @match.arena_participations.npcs.find_by(id: participation_id)
    end

    # Legacy NPC template target (format: "npc-123")
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
          id: "npc-participation-#{p.id}",
          character_id: "npc-participation-#{p.id}",
          name: npc.name,
          character_name: npc.name,
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

  def current_user_waiting?
    participation = current_user_participation
    pending_turn = participation&.metadata.to_h["pending_turn"]

    pending_turn.present? &&
      pending_turn["turn_number"].to_i == (@match.current_turn_number || 1).to_i
  end

  def current_user_combat_data
    participation = current_user_participation
    return nil unless participation

    profile = Arena::CombatProfile.for_participation(participation, persist: true)
    {
      current_ap: [participation.metadata&.dig("current_ap") || profile["ap_limit"], profile["ap_limit"]].min,
      max_ap: profile["ap_limit"],
      simple_attack_cost: profile["simple_attack_cost"],
      aimed_attack_cost: profile["aimed_attack_cost"],
      physical_attack_cost_seed: profile["physical_attack_cost_seed"]
    }
  end
end

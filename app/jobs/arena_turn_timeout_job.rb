# frozen_string_literal: true

# Purpose: Checks for arena matches where a turn has timed out and auto-resolves them
#
# Inputs:
#   - match_id [Integer] - Optional specific match to check, or checks all live matches
#
# Returns:
#   - nil (side effects: updates match state, broadcasts timeout)
#
# Usage:
#   ArenaTurnTimeoutJob.perform_later(match_id: 123)  # Check specific match
#   ArenaTurnTimeoutJob.perform_later                 # Check all live matches
#
class ArenaTurnTimeoutJob < ApplicationJob
  queue_as :arena

  def perform(match_id: nil)
    if match_id
      check_single_match(match_id)
    else
      check_all_live_matches
    end
  end

  private

  def check_single_match(match_id)
    match = ArenaMatch.find_by(id: match_id)
    return unless match&.live?
    return if match.auto_end_if_needed!

    process_timeout(match) if match.turn_timed_out?
  end

  def check_all_live_matches
    ArenaMatch.live.find_each do |match|
      next if match.auto_end_if_needed!

      process_timeout(match) if match.turn_timed_out?
    end
  end

  def process_timeout(match)
    processor = Arena::CombatProcessor.new(match)

    # PvP: waiting player may claim victory/draw.
    if processor.pending_player_turns?
      processor.mark_timeout_claim_available!
      broadcast_timeout(match, claim_available: true)
      return
    end

    # Wilderness NPC fight: player went AFK — bots win by timeout. The player
    # must still open the match and press Finish; we do not silently dismiss.
    if processor.npc_fight? && !processor.player_turn_commit_required?
      npc_team = match.arena_participations.npcs
        .detect { |row| row.current_hp.to_i.positive? }
        &.team || match.arena_participations.npcs.first&.team
      Arena::CombatLogRecorder.new(match).record!(
        entry_type: "timeout",
        actor: nil,
        description: I18n.t("game.fight.fight_timeout")
      )
      processor.end_match(npc_team, reason: :timeout)
      broadcast_timeout(match, claim_available: false)
      return
    end

    Arena::CombatLogRecorder.new(match).record!(
      entry_type: "timeout",
      actor: nil,
      description: "Turn #{match.current_turn_number} ended by timeout"
    )

    match.advance_turn!(timed_out: true)
    broadcast_timeout(match, claim_available: false)

    if processor.npc_fight? && !processor.player_turn_commit_required?
      processor.process_npc_turn
    end

    check_excessive_timeouts(match, processor)
  end

  def broadcast_timeout(match, claim_available:)
    message = if claim_available
      I18n.t("game.fight.turn_timeout_claim")
    else
      I18n.t("game.fight.turn_ended_by_timeout")
    end

    Arena::CombatBroadcaster.new(match).broadcast_event(
      {
        type: "turn_timeout",
        message: message,
        turn_number: match.current_turn_number,
        current_team: match.current_turn_team,
        claim_available: claim_available,
        timestamp: Time.current.strftime("%H:%M:%S")
      }
    )
  end

  def check_excessive_timeouts(match, processor)
    timeout_count = match.metadata&.dig("timeout_count") || 0
    match.metadata["timeout_count"] = timeout_count + 1
    match.save!

    if timeout_count >= 3
      processor.end_match(nil, reason: :timeout)
    end
  end
end

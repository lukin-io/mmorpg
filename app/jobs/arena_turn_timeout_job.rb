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

    process_timeout(match) if match.turn_timed_out?
  end

  def check_all_live_matches
    ArenaMatch.live.find_each do |match|
      process_timeout(match) if match.turn_timed_out?
    end
  end

  def process_timeout(match)
    processor = Arena::CombatProcessor.new(match)

    # Log the timeout
    match.metadata ||= {}
    match.metadata["combat_log"] ||= []
    match.metadata["combat_log"] << {
      "type" => "timeout",
      "timestamp" => Time.current.strftime("%H:%M:%S"),
      "description" => "Turn #{match.current_turn_number} ended by timeout"
    }

    # Mark turn as timed out and advance to next turn
    match.advance_turn!(timed_out: true)

    # Broadcast timeout to all participants
    broadcast_timeout(match)

    # If NPC fight, process NPC turn
    if processor.npc_fight?
      processor.process_npc_turn
    end

    # Check if match should end after too many timeouts
    check_excessive_timeouts(match, processor)

    # Schedule next timeout check
    schedule_next_check(match)
  end

  def broadcast_timeout(match)
    ActionCable.server.broadcast(
      match.broadcast_channel,
      {
        type: "turn_timeout",
        message: "Turn ended by timeout",
        turn_number: match.current_turn_number,
        current_team: match.current_turn_team,
        timestamp: Time.current.strftime("%H:%M:%S")
      }
    )

    # Also broadcast warning 30 seconds before timeout if scheduling
    remaining = match.seconds_until_timeout
    if remaining && remaining > 30
      ArenaTurnTimeoutWarningJob.set(wait: (remaining - 30).seconds).perform_later(match_id: match.id)
    end
  end

  def check_excessive_timeouts(match, processor)
    timeout_count = match.metadata&.dig("timeout_count") || 0
    match.metadata["timeout_count"] = timeout_count + 1
    match.save!

    # End match after 3 consecutive timeouts from same team
    if timeout_count >= 3
      processor.end_match(nil) # Draw due to inactivity
    end
  end

  def schedule_next_check(match)
    return unless match.live?

    timeout_seconds = match.turn_timeout_seconds || 300
    ArenaTurnTimeoutJob.set(wait: timeout_seconds.seconds).perform_later(match_id: match.id)
  end
end

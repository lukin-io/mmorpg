# frozen_string_literal: true

# Purpose: Broadcasts a warning that a turn is about to timeout
#
# Inputs:
#   - match_id [Integer] - The arena match to warn about
#   - seconds_remaining [Integer] - How many seconds remain (default 30)
#
# Returns:
#   - nil (side effects: broadcasts warning to match channel)
#
# Usage:
#   ArenaTurnTimeoutWarningJob.perform_later(match_id: 123, seconds_remaining: 30)
#
class ArenaTurnTimeoutWarningJob < ApplicationJob
  queue_as :arena

  def perform(match_id:, seconds_remaining: 30)
    match = ArenaMatch.find_by(id: match_id)
    return unless match&.live?

    # Only warn if the turn is still the same (hasn't been submitted)
    actual_remaining = match.seconds_until_timeout
    return unless actual_remaining && actual_remaining <= seconds_remaining + 5

    ActionCable.server.broadcast(
      match.broadcast_channel,
      {
        type: "turn_timeout_warning",
        seconds_remaining: actual_remaining,
        message: "#{actual_remaining} seconds remaining!",
        current_team: match.current_turn_team,
        timestamp: Time.current.strftime("%H:%M:%S")
      }
    )

    # Schedule final warnings at 10s and 5s
    if seconds_remaining > 10
      ArenaTurnTimeoutWarningJob.set(wait: (actual_remaining - 10).seconds)
        .perform_later(match_id: match_id, seconds_remaining: 10)
    elsif seconds_remaining > 5
      ArenaTurnTimeoutWarningJob.set(wait: (actual_remaining - 5).seconds)
        .perform_later(match_id: match_id, seconds_remaining: 5)
    end
  end
end

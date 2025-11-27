# frozen_string_literal: true

module Arena
  # Job to start an arena match after countdown
  # Scheduled when applications are matched
  #
  class MatchStarterJob < ApplicationJob
    queue_as :arena

    def perform(match_id)
      match = ArenaMatch.find_by(id: match_id)
      return unless match
      return unless match.pending?

      match.update!(
        status: :live,
        started_at: Time.current
      )

      # Set all participants to in-combat
      match.characters.update_all(in_combat: true, last_combat_at: Time.current)

      # Broadcast match start
      broadcaster = Arena::CombatBroadcaster.new(match)
      broadcaster.broadcast_match_start
    end
  end
end


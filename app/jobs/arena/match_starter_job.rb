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

      Arena::CombatProcessor.new(match).start_match
    end
  end
end

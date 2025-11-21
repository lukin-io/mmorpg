# frozen_string_literal: true

module Leaderboards
  # Recomputes leaderboard rankings by score.
  #
  # Usage:
  #   Leaderboards::RankCalculator.new(leaderboard).recalculate!
  class RankCalculator
    def initialize(leaderboard)
      @leaderboard = leaderboard
    end

    def recalculate!
      leaderboard.leaderboard_entries.order(score: :desc).each_with_index do |entry, index|
        entry.update!(rank: index + 1)
      end
    end

    private

    attr_reader :leaderboard
  end
end


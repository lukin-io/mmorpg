# frozen_string_literal: true

class LeaderboardsController < ApplicationController
  def index
    @leaderboards = policy_scope(Leaderboard).order(starts_at: :desc)
  end

  def show
    @leaderboard = authorize Leaderboard.find(params[:id])
    @entries = @leaderboard.leaderboard_entries.order(rank: :asc)
  end

  def recalculate
    leaderboard = authorize Leaderboard.find(params[:id])
    Leaderboards::RankCalculator.new(leaderboard).recalculate!
    redirect_to leaderboard, notice: "Leaderboard recalculated."
  end
end


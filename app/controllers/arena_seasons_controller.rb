# frozen_string_literal: true

# Manages arena season display and leaderboards.
#
# @example View current and past seasons
#   GET /arena_seasons
#
# @example View season leaderboard
#   GET /arena_seasons/:id
#
class ArenaSeasonsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def index
    @current_season = ArenaSeason.active.first
    @past_seasons = ArenaSeason.where("ends_at < ?", Time.current).order(ends_at: :desc).limit(10)
  end

  def show
    @arena_season = ArenaSeason.find(params[:id])
    @rankings = @arena_season.arena_rankings
      .includes(character: :user)
      .order(rating: :desc)
      .page(params[:page])
      .per(50)
  end
end

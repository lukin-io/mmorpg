# frozen_string_literal: true

class ArenaSeasonsController < ApplicationController
  def index
    @arena_seasons = ArenaSeason.order(starts_at: :desc)
  end

  def show
    @arena_season = ArenaSeason.find_by!(slug: params[:id])
    @recent_matches = @arena_season.arena_matches.recent.limit(20)
  end
end

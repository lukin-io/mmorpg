# frozen_string_literal: true

class ActivityController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  def show
    tracker = Game::Activity::Tracker.new(character: current_character)
    tracker.ensure_daily_contracts!
    tracker.ensure_achievement_rows!
    day = Time.current.utc.strftime("%Y-%m-%d")
    @contracts = DailyActivityContract.where(character: current_character, day_key: day).order(:id)
    @achievements = ActivityAchievement.where(character: current_character).order(Arel.sql("completed_at NULLS LAST"), :id)
    @claim_streak = current_character.metadata.to_h.dig("activity_streak", "count").to_i
    @live_events =     Game::WorldEvents::Pulse.new.call(scope: :board).first(6)
    @sector_wars = Game::World::SectorWarBoard.new.call
    @siege_rows = @sector_wars.select(&:under_siege)
    @checkin = Game::Seasons::DailyCheckin.new(character: current_character).call
    Game::Onboarding::FirstHour.new(character: current_character).mark!("open_activity")
  end

  def claim
    kind = params[:kind].to_s
    id = params[:id].to_i
    result = Game::Activity::ClaimReward.new(character: current_character, kind:, id:).call
    redirect_to activity_path, status: :see_other, **(result.success? ? {notice: result.message} : {alert: result.message})
  end
end

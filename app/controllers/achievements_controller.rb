# frozen_string_literal: true

class AchievementsController < ApplicationController
  def index
    @achievements = policy_scope(Achievement).order(points: :desc)
    @grants = current_user.achievement_grants.includes(:achievement)
  end

  def create
    achievement = authorize Achievement.find(params[:achievement_id])
    Achievements::GrantService.new(user: current_user, achievement:).call(source: "manual_unlock")
    redirect_to achievements_path, notice: "Achievement unlocked!"
  end
end

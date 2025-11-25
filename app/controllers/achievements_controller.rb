# frozen_string_literal: true

class AchievementsController < ApplicationController
  def index
    achievements = policy_scope(Achievement).ordered_for_showcase
    achievements = achievements.where(category: params[:category]) if params[:category].present?
    @achievements = achievements
    @grants = current_user.achievement_grants.includes(:achievement)
    @showcase = Achievements::ProfileShowcaseBuilder.new(user: current_user).call
  end

  def create
    achievement = authorize Achievement.find(params[:achievement_id])
    Achievements::GrantService.new(user: current_user, achievement:).call(source: "manual_unlock")
    redirect_to achievements_path, notice: "Achievement unlocked!"
  end
end

# frozen_string_literal: true

class ProfessionsController < ApplicationController
  def index
    @professions = policy_scope(Profession).order(:name)
    @progresses = current_user.profession_progresses.includes(:profession)
  end

  def update_progress
    profession = Profession.find(params[:id])
    progress = current_user.profession_progresses.find_or_initialize_by(profession:)
    authorize progress

    progress.increment!(:skill_level)
    redirect_to professions_path, notice: "Profession leveled up."
  end
end


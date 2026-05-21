# frozen_string_literal: true

class ProfessionsController < ApplicationController
  before_action :ensure_active_character!

  def index
    @professions = policy_scope(Profession).order(:category, :name)
    @progresses =
      current_character.profession_progresses
        .includes(:profession, :equipped_tool)
        .index_by(&:profession_id)
    @tools = current_character.profession_tools.includes(:profession)
  end

  def enroll
    profession = Profession.find(params[:id])
    authorize ProfessionProgress, :enroll?

    Professions::EnrollmentService.new(
      character: current_character,
      profession:
    ).enroll!

    redirect_to professions_path, notice: "#{profession.name} unlocked."
  rescue => e
    redirect_to professions_path, alert: e.message
  end
end

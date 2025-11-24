# frozen_string_literal: true

class CraftingJobsController < ApplicationController
  before_action :ensure_active_character!

  def index
    authorize CraftingJob
    @crafting_jobs =
      policy_scope(CraftingJob)
        .for_character(current_character)
        .order(completes_at: :asc)
    @recipes = Recipe.includes(:profession).order(:name)
    @stations = CraftingStation.order(:name)
  end

  def create
    recipe = Recipe.find(crafting_job_params[:recipe_id])
    station = CraftingStation.find(crafting_job_params[:crafting_station_id])
    authorize CraftingJob.new(user: current_user, character: current_character, recipe:, crafting_station: station)

    jobs = Crafting::JobScheduler.new(
      user: current_user,
      character: current_character,
      recipe:,
      station:
    ).enqueue!(quantity: crafting_job_params[:quantity].to_i)

    job_label = "job".pluralize(jobs.size)
    redirect_to crafting_jobs_path,
      notice: "#{jobs.size} crafting #{job_label} queued."
  rescue => e
    redirect_to crafting_jobs_path, alert: e.message
  end

  def preview
    authorize CraftingJob, :preview?
    recipe = Recipe.find(preview_params[:recipe_id])
    station = CraftingStation.find(preview_params[:crafting_station_id])
    validator = Crafting::RecipeValidator.new(character: current_character, recipe:, station:)
    validator.validate!
    @preview = Professions::CraftingOutcomeCalculator.new(
      progress: validator.profession_progress,
      recipe:,
      station:
    ).preview

    respond_to do |format|
      format.turbo_stream
    end
  rescue => e
    render turbo_stream: turbo_stream.update(
      "crafting-preview",
      e.message
    ), status: :unprocessable_entity
  end

  private

  def crafting_job_params
    params.require(:crafting_job).permit(:recipe_id, :crafting_station_id, :quantity)
  end

  def preview_params
    params.require(:crafting_job).permit(:recipe_id, :crafting_station_id)
  end
end

# frozen_string_literal: true

class CraftingJobsController < ApplicationController
  def index
    @crafting_jobs = policy_scope(CraftingJob).where(user: current_user).order(completes_at: :asc)
  end

  def create
    recipe = Recipe.find(crafting_job_params[:recipe_id])
    station = CraftingStation.find(crafting_job_params[:crafting_station_id])
    authorize CraftingJob.new(recipe:, crafting_station: station), :create?

    job = Crafting::JobScheduler.new(user: current_user, recipe:, station:).enqueue!
    redirect_to crafting_jobs_path, notice: "Crafting job queued (completes at #{job.completes_at.to_formatted_s(:long)})"
  rescue StandardError => e
    redirect_to crafting_jobs_path, alert: e.message
  end

  private

  def crafting_job_params
    params.require(:crafting_job).permit(:recipe_id, :crafting_station_id)
  end
end


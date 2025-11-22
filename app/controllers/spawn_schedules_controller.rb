# frozen_string_literal: true

class SpawnSchedulesController < ApplicationController
  def index
    authorize SpawnSchedule
    @region_catalog = Game::World::RegionCatalog.instance
    @population_directory = Game::World::PopulationDirectory.instance
    @spawn_schedules = policy_scope(SpawnSchedule).order(:region_key, :monster_key)
    @spawn_schedule = SpawnSchedule.new
  end

  def create
    @spawn_schedule = authorize SpawnSchedule.new(spawn_schedule_params.merge(configured_by: current_user))
    if @spawn_schedule.save
      redirect_to spawn_schedules_path, notice: "Spawn schedule created."
    else
      index
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @spawn_schedule = authorize SpawnSchedule.find(params[:id])
    if @spawn_schedule.update(spawn_schedule_params)
      respond_to do |format|
        format.html { redirect_to spawn_schedules_path, notice: "Spawn schedule updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to spawn_schedules_path, alert: "Unable to update spawn schedule." }
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
  end

  private

  def spawn_schedule_params
    params.require(:spawn_schedule).permit(:region_key, :monster_key, :respawn_seconds, :rarity_override, :active)
  end
end

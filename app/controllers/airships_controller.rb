# frozen_string_literal: true

class AirshipsController < ApplicationController
  before_action :ensure_active_character!

  rescue_from Game::World::AirshipTravel::TravelViolationError,
    Economy::WalletService::InsufficientFundsError, with: :reject_travel

  def show
    @airship_state = travel.state
    unless @airship_state
      respond_to do |format|
        format.json { render json: {phase: "disembarked"} }
        format.html { redirect_to resume_path, status: :see_other }
      end
      return
    end

    @active_airship_journey = @airship_state.journey
    @position = @airship_state.position
    @airship_server_now = Time.current
    prepare_presence_context if request.format.html?
    response.headers["Cache-Control"] = "no-store"
    respond_to do |format|
      format.html
      format.json { render json: map_snapshot }
    end
  end

  def create
    travel.board!(action_key: params[:action_key])
    redirect_to resume_path, status: :see_other
  end

  def disembark
    travel.disembark!(journey_id: params[:journey_id])
    redirect_to resume_path, status: :see_other
  end

  private

  def travel
    @travel ||= Game::World::AirshipTravel.new(character: current_character)
  end

  def resume_path
    Game::World::ResumeContext.new(character: current_character).resume_path
  end

  def reject_travel(error)
    redirect_to resume_path, alert: error.message, status: :see_other
  end

  def map_snapshot
    map = @airship_state.map
    {
      phase: @airship_state.phase,
      deadline: @airship_state.deadline&.iso8601(6),
      server_now: @airship_server_now.iso8601(6),
      center_x: map.center_x, center_y: map.center_y,
      velocity_x: map.velocity_x, velocity_y: map.velocity_y,
      motion_ends_at: map.motion_ends_at&.iso8601(6),
      map_html: render_to_string(partial: "airships/map", formats: [:html], locals: {map:})
    }
  end
end

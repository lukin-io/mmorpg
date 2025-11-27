# frozen_string_literal: true

# Arena applications controller - create, accept, cancel fight applications
class ArenaApplicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  before_action :set_room, only: [:index, :create]
  before_action :set_application, only: [:accept, :destroy, :cancel]

  # GET /arena_rooms/:arena_room_id/arena_applications
  def index
    @applications = @room.arena_applications
      .open
      .includes(:applicant)
      .order(created_at: :asc)

    respond_to do |format|
      format.html { render partial: "arena_applications/list", locals: {applications: @applications} }
      format.json { render json: applications_payload }
    end
  end

  # POST /arena_rooms/:arena_room_id/arena_applications
  def create
    handler = Arena::ApplicationHandler.new
    result = handler.create(
      character: current_character,
      room: @room,
      params: application_params
    )

    respond_to do |format|
      if result.success?
        format.html { redirect_to arena_room_path(@room), notice: "Application submitted!" }
        format.json { render json: {success: true, application: result.application}, status: :created }
      else
        format.html { redirect_to arena_room_path(@room), alert: result.errors.join(", ") }
        format.json { render json: {success: false, errors: result.errors}, status: :unprocessable_entity }
      end
    end
  end

  # POST /arena_rooms/:arena_room_id/arena_applications/:id/accept
  # POST /arena_applications/:id/accept
  def accept
    handler = Arena::ApplicationHandler.new
    result = handler.accept(
      application: @application,
      acceptor: current_character
    )

    respond_to do |format|
      if result.success?
        format.html { redirect_to arena_match_path(result.match), notice: "Fight accepted! Get ready!" }
        format.json do
          render json: {
            success: true,
            match_id: result.match.id,
            countdown: @application.timeout_seconds
          }
        end
      else
        format.html { redirect_back fallback_location: arena_path, alert: result.errors.join(", ") }
        format.json { render json: {success: false, errors: result.errors}, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /arena_rooms/:arena_room_id/arena_applications/:id
  # DELETE /arena_applications/:id/cancel
  def destroy
    cancel
  end

  def cancel
    handler = Arena::ApplicationHandler.new
    result = handler.cancel(
      application: @application,
      character: current_character
    )

    respond_to do |format|
      if result.success?
        format.html { redirect_to arena_room_path(@application.arena_room), notice: "Application cancelled" }
        format.json { render json: {success: true} }
      else
        format.html { redirect_back fallback_location: arena_path, alert: result.errors.join(", ") }
        format.json { render json: {success: false, errors: result.errors}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_room
    @room = ArenaRoom.find(params[:arena_room_id])
  end

  def set_application
    @application = ArenaApplication.find(params[:id])
  end

  def require_character
    unless current_character
      redirect_to root_path, alert: "You need a character to enter the arena"
    end
  end

  def current_character
    @current_character ||= current_user.characters.first
  end
  helper_method :current_character

  def application_params
    params.require(:arena_application).permit(
      :fight_type, :fight_kind, :timeout_seconds, :trauma_percent,
      :team_count, :team_level_min, :team_level_max,
      :enemy_count, :enemy_level_min, :enemy_level_max,
      :wait_minutes, :closed_fight
    )
  rescue ActionController::ParameterMissing
    params.permit(
      :fight_type, :fight_kind, :timeout_seconds, :trauma_percent,
      :team_count, :team_level_min, :team_level_max,
      :enemy_count, :enemy_level_min, :enemy_level_max,
      :wait_minutes, :closed_fight
    )
  end

  def applications_payload
    @applications.map do |app|
      {
        id: app.id,
        fight_type: app.fight_type,
        fight_kind: app.fight_kind,
        applicant: {
          id: app.applicant.id,
          name: app.applicant.name,
          level: app.applicant.level
        },
        expires_in: app.time_until_expiration,
        acceptable: app.acceptable_by?(current_character)
      }
    end
  end
end

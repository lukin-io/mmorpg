# frozen_string_literal: true

# Arena applications controller - create, accept, cancel fight applications
class ArenaApplicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  before_action :require_city_arena_entry!
  before_action :set_room, only: [:index, :create]
  before_action :ensure_room_access!, only: :index
  before_action :set_application, only: [:accept, :destroy, :cancel]

  # GET /arena_rooms/:arena_room_id/arena_applications
  def index
    @applications = @room.arena_applications
      .open
      .where(fight_type: ArenaApplication::AVAILABLE_FIGHT_TYPES)
      .includes(:applicant, :npc_template, arena_application_memberships: :character)
      .order(created_at: :asc).limit(100)

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
        format.html { redirect_to arena_room_path(@room, ft: result.application.team_battle? ? 2 : 1), notice: "Application submitted." }
        format.json { render json: {success: true, application: result.application}, status: :created }
      else
        format.html { redirect_to arena_room_path(@room, ft: application_params[:fight_type] == "team_battle" ? 2 : 1), alert: result.errors.join(", ") }
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
      acceptor: current_character,
      team: params[:team]
    )

    respond_to do |format|
      if result.success?
        destination = result.match ? arena_match_path(result.match) : arena_room_path(@application.arena_room, ft: 2)
        format.html { redirect_to destination, notice: "Application accepted." }
        format.json do
          render json: {
            success: true,
            match_id: result.match&.id,
            countdown: result.match ? (result.match.live? ? 0 : 10) : nil,
            redirect_url: destination
          }
        end
      else
        format.html { redirect_back fallback_location: arena_index_path, alert: result.errors.join(", ") }
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
        format.html { redirect_to arena_room_path(@application.arena_room, ft: @application.team_battle? ? 2 : 1), notice: "Application canceled." }
        format.json { render json: {success: true} }
      else
        format.html { redirect_back fallback_location: arena_index_path, alert: result.errors.join(", ") }
        format.json { render json: {success: false, errors: result.errors}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_room
    @room = ArenaRoom.find(params[:arena_room_id])
  end

  def ensure_room_access!
    return if @room.accessible_by?(current_character)

    respond_to do |format|
      format.html { redirect_to arena_index_path, alert: "This arena room is unavailable." }
      format.json do
        render json: {success: false, errors: ["This arena room is unavailable."]}, status: :forbidden
      end
    end
  end

  def set_application
    scope = params[:arena_room_id] ? ArenaApplication.where(arena_room_id: params[:arena_room_id]) : ArenaApplication.all
    @application = scope.find(params[:id])
  end

  def require_character
    unless current_character
      redirect_to root_path, alert: "A character is required to enter the arena."
    end
  end

  def current_character
    @current_character ||= current_user.character
  end
  helper_method :current_character

  def application_params
    params.require(:arena_application).permit(
      :fight_type, :fight_kind, :timeout_seconds, :trauma_percent,
      :team_count, :team_level_min, :team_level_max,
      :enemy_count, :enemy_level_min, :enemy_level_max,
      :wait_minutes
    )
  rescue ActionController::ParameterMissing
    params.permit(
      :fight_type, :fight_kind, :timeout_seconds, :trauma_percent,
      :team_count, :team_level_min, :team_level_max,
      :enemy_count, :enemy_level_min, :enemy_level_max,
      :wait_minutes
    )
  end

  def applications_payload
    @applications.map do |app|
      {
        id: app.id,
        fight_type: app.fight_type,
        fight_kind: app.fight_kind,
        applicant: {
          id: app.npc_application? ? "npc-#{app.npc_template_id}" : app.applicant.id,
          name: app.applicant_name,
          level: app.applicant_level
        },
        expires_in: app.time_until_expiration,
        acceptable: app.acceptable_by?(current_character)
      }
    end
  end
end

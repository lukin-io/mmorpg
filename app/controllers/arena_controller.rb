# frozen_string_literal: true

# Main arena controller - lobby and room overview
class ArenaController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  around_action :with_city_arena_entry

  # GET /arena
  # Arena lobby showing all rooms
  def index
    if (result = current_character.unfinished_arena_result)
      redirect_to arena_match_path(result)
      return
    end
    # Check if user is already in an active match - redirect them there
    active_participation = current_character.arena_participations
      .joins(:arena_match)
      .where(arena_matches: {status: [:pending, :matching, :live]})
      .first

    if active_participation
      redirect_to arena_match_path(active_participation.arena_match),
        notice: "You already have an active fight."
      return
    end

    @rooms = ArenaRoom.active.where(zone_id: [nil, current_character.position&.zone_id]).order(:room_type)
    @current_application = current_character.waiting_arena_application
    if @current_application
      redirect_to arena_room_path(@current_application.arena_room, ft: @current_application.team_battle? ? 2 : 1)
      return
    end
    @recent_matches = current_character.arena_participations
      .includes(:arena_match)
      .order(created_at: :desc)
      .limit(5)

    respond_to do |format|
      format.html do
        context = Game::World::ResumeContext.new(character: current_character)
        context.remember_world! unless context.arena_room
        prepare_presence_context
      end
      format.json { render json: arena_lobby_payload }
    end
  end

  # GET /arena/lobby
  # Turbo frame for lobby updates
  def lobby
    @rooms = ArenaRoom.active.where(zone_id: [nil, current_character.position&.zone_id]).order(:room_type)
    render partial: "arena/lobby", locals: {rooms: @rooms}
  end

  private

  def require_character
    unless current_character
      redirect_to root_path, alert: "A character is required to enter the arena."
    end
  end

  def current_character
    @current_character ||= current_user.character
  end
  helper_method :current_character

  def arena_lobby_payload
    {
      rooms: @rooms.map do |room|
        {
          id: room.id,
          name: room.name,
          slug: room.slug,
          room_type: room.room_type,
          level_range: "#{room.level_min}-#{room.level_max}",
          alignment: room.alignment_restriction,
          accessible: room.accessible_by?(current_character),
          open_applications: room.open_application_count,
          active_matches: room.current_match_count
        }
      end,
      current_application: @current_application&.as_json(
        only: [:id, :fight_type, :fight_kind, :status, :expires_at]
      )
    }
  end
end

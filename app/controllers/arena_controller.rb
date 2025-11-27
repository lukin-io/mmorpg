# frozen_string_literal: true

# Main arena controller - lobby and room overview
class ArenaController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character

  # GET /arena
  # Arena lobby showing all rooms
  def index
    @rooms = ArenaRoom.active.order(:room_type)
    @current_application = current_character.arena_applications.active.first
    @recent_matches = current_character.arena_participations
      .includes(:arena_match)
      .order(created_at: :desc)
      .limit(5)

    respond_to do |format|
      format.html
      format.json { render json: arena_lobby_payload }
    end
  end

  # GET /arena/lobby
  # Turbo frame for lobby updates
  def lobby
    @rooms = ArenaRoom.active.order(:room_type)
    render partial: "arena/lobby", locals: {rooms: @rooms}
  end

  private

  def require_character
    unless current_character
      redirect_to root_path, alert: "You need a character to enter the arena"
    end
  end

  def current_character
    @current_character ||= current_user.characters.first
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
          faction: room.faction_restriction,
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

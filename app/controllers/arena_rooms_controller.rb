# frozen_string_literal: true

# Arena rooms controller - view rooms and their applications
class ArenaRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  before_action :set_room, only: :show

  # GET /arena_rooms
  def index
    @rooms = ArenaRoom.active.order(:room_type)

    respond_to do |format|
      format.html
      format.json { render json: rooms_payload }
    end
  end

  # GET /arena_rooms/:id
  def show
    unless @room.accessible_by?(current_character)
      redirect_to arena_rooms_path, alert: "You cannot access this arena room"
      return
    end

    @applications = @room.arena_applications
      .open
      .includes(:applicant)
      .order(created_at: :asc)

    @my_application = current_character.arena_applications.active.first
    @active_matches = @room.arena_matches.active.includes(:arena_participations)

    respond_to do |format|
      format.html
      format.json { render json: room_payload }
    end
  end

  private

  def set_room
    @room = ArenaRoom.find(params[:id])
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

  def rooms_payload
    @rooms.map do |room|
      {
        id: room.id,
        name: room.name,
        slug: room.slug,
        room_type: room.room_type,
        level_range: "#{room.level_min}-#{room.level_max}",
        faction: room.faction_restriction,
        accessible: room.accessible_by?(current_character),
        open_applications: room.open_application_count
      }
    end
  end

  def room_payload
    {
      room: {
        id: @room.id,
        name: @room.name,
        level_range: "#{@room.level_min}-#{@room.level_max}",
        faction: @room.faction_restriction
      },
      applications: @applications.map do |app|
        {
          id: app.id,
          fight_type: app.fight_type,
          fight_kind: app.fight_kind,
          applicant: {
            id: app.applicant.id,
            name: app.applicant.name,
            level: app.applicant.level
          },
          timeout_seconds: app.timeout_seconds,
          trauma_percent: app.trauma_percent,
          expires_at: app.expires_at&.iso8601,
          acceptable: app.acceptable_by?(current_character)
        }
      end,
      my_application: @my_application&.as_json(
        only: [:id, :fight_type, :fight_kind, :status, :expires_at]
      )
    }
  end
end

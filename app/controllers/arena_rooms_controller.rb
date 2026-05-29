# frozen_string_literal: true

# Arena rooms controller - view rooms and their applications
class ArenaRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  before_action :require_city_arena_entry!
  before_action :set_room, only: :show

  # GET /arena_rooms/:id
  def show
    unless @room.accessible_by?(current_character)
      redirect_to arena_index_path, alert: "This arena room is unavailable."
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

    @applications = @room.arena_applications
      .open
      .includes(:applicant, :npc_template)
      .order(created_at: :asc)

    # Only show open applications as "my application", not matched ones
    @my_application = current_character.arena_applications.open.first
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
      redirect_to root_path, alert: "A character is required to enter the arena."
    end
  end

  def current_character
    @current_character ||= current_user.characters.first
  end
  helper_method :current_character

  def room_payload
    {
      room: {
        id: @room.id,
        name: @room.name,
        level_range: "#{@room.level_min}-#{@room.level_max}",
        alignment: @room.alignment_restriction
      },
      applications: @applications.map do |app|
        {
          id: app.id,
          fight_type: app.fight_type,
          fight_kind: app.fight_kind,
          applicant: {
            id: app.npc_application? ? "npc-#{app.npc_template_id}" : app.applicant.id,
            name: app.npc_application? ? app.npc_template.name : app.applicant.name,
            level: app.npc_application? ? app.npc_template.level : app.applicant.level
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

# frozen_string_literal: true

# Arena rooms controller - view rooms and their applications
class ArenaRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_character
  around_action :with_city_arena_entry
  before_action :set_room, only: :show

  # GET /arena_rooms/:id
  def show
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

    context = Game::World::ResumeContext.new(character: current_character)
    unless context.arena_room_available?(room: @room)
      redirect_to arena_index_path, alert: "This arena room is unavailable."
      return
    end

    @my_application = current_character.waiting_arena_application
    if @my_application && @my_application.arena_room_id != @room.id
      redirect_to arena_room_path(@my_application.arena_room, ft: @my_application.team_battle? ? 2 : 1)
      return
    end
    @active_tab = params[:ft].to_s == "2" ? "2" : "1"
    @active_tab = @my_application.team_battle? ? "2" : "1" if @my_application
    @own_level_filter = params[:level] != "all"
    @applications = @room.arena_applications
      .open
      .where(fight_type: @active_tab == "2" ? :team_battle : :duel)
      .includes(:applicant, :npc_template, arena_application_memberships: :character)
      .order(created_at: :asc)
      .limit(100)
    @applications = @applications.select do |application|
      !@own_level_filter || application.member?(current_character) ||
        (application.team_battle? ? %w[a b].any? { |team| application.side_level_range(team).cover?(current_character.level) } : application.level_matches?(current_character))
    end

    # Only show open applications as "my application", not matched ones
    @active_matches = @room.arena_matches.active.includes(arena_participations: [:character, :npc_template]).limit(20)

    respond_to do |format|
      format.html do
        unless context.remember_arena_room!(room: @room)
          redirect_to arena_index_path, alert: "This arena room is unavailable."
          next
        end
        prepare_presence_context
        @rooms = ArenaRoom.active.where(zone_id: [nil, current_character.position&.zone_id]).order(:room_type)
      end
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
    @current_character ||= current_user.character
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

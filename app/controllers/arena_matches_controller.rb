# frozen_string_literal: true

class ArenaMatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_arena_match, only: [:show, :action, :spectate, :log]
  before_action :require_character, only: [:action]
  before_action :require_participant, only: [:action]

  def index
    @arena_matches = policy_scope(ArenaMatch).recent.includes(arena_participations: :character)
    @arena_match = ArenaMatch.new
  end

  def show
    authorize @arena_match

    # Auto-end stale or finished matches
    if @arena_match.auto_end_if_needed!
      flash.now[:notice] = "Match ended due to timeout or completion."
    end

    @participations = @arena_match.arena_participations.includes(:character, :npc_template)
    @broadcaster = Arena::CombatBroadcaster.new(@arena_match)

    respond_to do |format|
      format.html
      format.json { render json: match_payload }
    end
  end

  # GET /arena_matches/:id/log
  def log
    authorize @arena_match, :show?
    @combat_log = @arena_match.metadata["combat_log"] || []

    respond_to do |format|
      format.html { render partial: "arena_matches/combat_log", locals: {log: @combat_log} }
      format.json { render json: {log: @combat_log} }
    end
  end

  def create
    current_user.ensure_social_features!
    authorize ArenaMatch

    participants = build_participants
    match = Arena::Matchmaker.new.queue!(
      participants: participants,
      match_type: params[:arena_match][:match_type] || :duel
    )

    redirect_to match, notice: "Arena match queued."
  rescue ArgumentError => e
    redirect_to arena_matches_path, alert: e.message
  end

  # POST /arena_matches/:id/action
  # Submit a combat action (attack, defend, skill, flee)
  def action
    authorize @arena_match

    processor = Arena::CombatProcessor.new(@arena_match)

    # Build params hash for the action
    action_params = {}
    action_params[:target] = find_action_target if params[:target_id].present?
    action_params[:skill_id] = params[:skill_id] if params[:skill_id].present?
    action_params[:attack_type] = params[:attack_type]&.to_sym if params[:attack_type].present?
    action_params[:body_part] = params[:body_part] if params[:body_part].present?
    if params[:block_parts].present?
      action_params[:block_parts] = params[:block_parts].is_a?(String) ? params[:block_parts].split(",") : Array(params[:block_parts])
    end
    action_params[:attacks] = turn_action_array(:attacks) if params[:attacks].present?
    action_params[:blocks] = turn_action_array(:blocks) if params[:blocks].present?
    action_params[:skills] = turn_action_array(:skills) if params[:skills].present?

    result = processor.process_action(
      current_character,
      params[:action_type].to_sym,
      **action_params
    )

    respond_to do |format|
      if result.success?
        format.html { redirect_to @arena_match, notice: "Action submitted!" }
        format.json { render json: {success: true, data: result.data} }
        format.turbo_stream { head :ok }
      else
        format.html { redirect_to @arena_match, alert: result.error }
        format.json { render json: {success: false, error: result.error}, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def spectate
    authorize @arena_match, :show?
    Arena::SpectatorBroadcaster.new(match: @arena_match).broadcast!(
      event: "spectator_joined",
      payload: {user_id: current_user.id, profile_name: current_user.profile_name}
    )

    redirect_to @arena_match, notice: "Spectator mode engaged."
  end

  private

  def require_character
    unless current_character
      redirect_to arena_index_path, alert: "You need a character to participate"
    end
  end

  def require_participant
    unless @arena_match.arena_participations.exists?(user: current_user)
      redirect_to @arena_match, alert: "You are not a participant in this match"
    end
  end

  def current_character
    @current_character ||= current_user.characters.first
  end
  helper_method :current_character

  def find_action_target
    target_id = params[:target_id]
    return nil unless target_id

    # Check if target is a character
    participation = @arena_match.arena_participations.find_by(character_id: target_id)
    return participation.character if participation&.character

    # Check if target is an NPC (format: "npc-123")
    if target_id.to_s.start_with?("npc-")
      npc_id = target_id.to_s.sub("npc-", "").to_i
      return @arena_match.arena_participations.find_by(npc_template_id: npc_id)
    end

    nil
  end

  def set_arena_match
    @arena_match = ArenaMatch.find(params[:id])
  end

  def match_payload
    {
      id: @arena_match.id,
      status: @arena_match.status,
      match_type: @arena_match.match_type,
      spectator_code: @arena_match.spectator_code,
      started_at: @arena_match.started_at&.iso8601,
      ended_at: @arena_match.ended_at&.iso8601,
      duration: @arena_match.duration,
      participants: @participations.map do |p|
        {
          character_id: p.character_id,
          character_name: p.character.name,
          team: p.team,
          result: p.result,
          rating_delta: p.rating_delta
        }
      end
    }
  end

  def build_participants
    character_ids = Array(params[:arena_match][:character_ids]).reject(&:blank?)
    raise ArgumentError, "Select at least two characters." if character_ids.size < 2

    characters = Character.includes(:user).where(id: character_ids)
    raise ArgumentError, "Characters not found." if characters.size < 2

    characters.each_with_index.map do |character, index|
      {
        character: character,
        user: character.user,
        team: (index.even? ? "alpha" : "beta")
      }
    end
  end

  def turn_action_array(key)
    Array(params[key]).map do |entry|
      entry.respond_to?(:to_unsafe_h) ? entry.to_unsafe_h : entry
    end
  end
end

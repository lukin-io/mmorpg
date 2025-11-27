# frozen_string_literal: true

class ArenaMatchesController < ApplicationController
  before_action :set_arena_match, only: [:show, :spectate, :log]

  def index
    @arena_matches = policy_scope(ArenaMatch).recent.includes(arena_participations: :character)
    @arena_match = ArenaMatch.new
  end

  def show
    authorize @arena_match
    @participations = @arena_match.arena_participations.includes(:character)
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
      format.html { render partial: "arena_matches/combat_log", locals: { log: @combat_log } }
      format.json { render json: { log: @combat_log } }
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

  def spectate
    authorize @arena_match, :show?
    Arena::SpectatorBroadcaster.new(match: @arena_match).broadcast!(
      event: "spectator_joined",
      payload: {user_id: current_user.id, profile_name: current_user.profile_name}
    )

    redirect_to @arena_match, notice: "Spectator mode engaged."
  end

  private

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
end

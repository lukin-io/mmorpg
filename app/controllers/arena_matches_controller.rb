# frozen_string_literal: true

class ArenaMatchesController < ApplicationController
  before_action :set_arena_match, only: [:show, :spectate]

  def index
    @arena_matches = policy_scope(ArenaMatch).recent.includes(arena_participations: :character)
    @arena_match = ArenaMatch.new
  end

  def show
    authorize @arena_match
    @participations = @arena_match.arena_participations.includes(:character)
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

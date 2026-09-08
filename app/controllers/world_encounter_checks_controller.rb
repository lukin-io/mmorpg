# frozen_string_literal: true

# Resolves the wilderness-only passive encounter check made by the game shell.
# The endpoint accepts no gameplay target from the client: the persisted
# character position and source-backed TileNpc placement remain authoritative.
class WorldEncounterChecksController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def create
    result = Game::World::PassiveEncounterCheck.new(
      character: current_character,
      return_context: "world"
    ).call

    if result.interrupted?
      render json: {
        interrupted: true,
        redirect_url: arena_match_path(result.match),
        message: result.message
      }
    else
      render json: {
        interrupted: false,
        retry_after_ms: result.retry_after_ms
      }
    end
  rescue Game::World::StartNpcFight::FightViolationError => error
    render json: {interrupted: false, error: error.message}, status: :unprocessable_content
  end
end

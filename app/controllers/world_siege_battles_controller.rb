# frozen_string_literal: true

# Starts a fortress siege duel between registered attack/defense participants.
class WorldSiegeBattlesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def create
    result = Game::World::FortressSiegeBattle.new(
      attacker: current_character,
      defender_id: params[:defender_id]
    ).call

    if result.success
      redirect_to arena_match_path(result.match), notice: result.message
    else
      redirect_to world_path, alert: result.message, status: :see_other
    end
  end
end

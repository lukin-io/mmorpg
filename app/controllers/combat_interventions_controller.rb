# frozen_string_literal: true

# Lists live fights and joins one as a Protection-scroll helper (team A/B).
class CombatInterventionsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def index
    Game::Professions::Templates.ensure_craft_items!
    @matches = Game::Combat::JoinAsProtector.live_joinable_matches.reject do |match|
      match.arena_participations.exists?(character_id: current_character.id)
    end
    @protection_owned = Game::Combat::AssaultScrolls.quantity(
      current_character,
      Game::Combat::AssaultScrolls::PROTECTION_KEY
    )
  end

  def create
    result = Game::Combat::JoinAsProtector.new(
      character: current_character,
      match_id: params[:match_id],
      team: params[:team]
    ).call

    if result.success
      redirect_to arena_match_path(result.match), notice: result.message
    else
      redirect_to combat_interventions_path, alert: result.message, status: :see_other
    end
  end
end

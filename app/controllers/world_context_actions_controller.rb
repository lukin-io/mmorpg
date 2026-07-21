# frozen_string_literal: true

# Routes the Neverlands-style world shell's Character and Inventory actions.
# A source-backed hostile NPC on the current wilderness cell can replace the
# intended navigation with the shared fight screen.
class WorldContextActionsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def create
    return_context = Game::World::CombatReturnContext.new(character: current_character).normalize(params[:context])
    interruption = Game::World::InterruptAction.new(
      character: current_character,
      return_context:
    ).call

    if interruption.interrupted?
      redirect_to arena_match_path(interruption.match), alert: interruption.message
    else
      redirect_to Game::World::CombatReturnContext.new(character: current_character).path_for(return_context)
    end
  rescue Game::World::CombatReturnContext::UnsupportedContextError => e
    redirect_to world_path, alert: e.message
  rescue Game::World::StartNpcFight::FightViolationError => e
    redirect_to world_path, alert: e.message
  end
end

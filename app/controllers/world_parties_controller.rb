# frozen_string_literal: true

class WorldPartiesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def invite
    result = Game::Parties::Roster.new(character: current_character).invite!(target_id: params[:target_id])
    redirect_world(result)
  end

  def accept
    result = Game::Parties::Roster.new(character: current_character).accept!
    redirect_world(result)
  end

  def leave
    result = Game::Parties::Roster.new(character: current_character).leave!
    redirect_world(result)
  end

  private

  def redirect_world(result)
    flash_key = result.success ? :notice : :alert
    redirect_to world_path, flash_key => result.message, status: :see_other
  end
end

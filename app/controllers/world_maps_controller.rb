# frozen_string_literal: true

class WorldMapsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  # Full 100×100 overview in a dedicated window (no turbo drive hijack).
  def show
    @map = Game::World::OverviewMap.new(character: current_character).call
  end
end

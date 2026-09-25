# frozen_string_literal: true

# Public Mist-style wars board — fortresses, sieges, scores. Does not invent
# outcomes; FortressClaim remains the authoritative mutation on-cell.
class WarsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  def show
    Game::WorldEvents::Pulse.new.call(scope: :board)
    @rows = Game::World::SectorWarBoard.new.call
    @sieges = @rows.select(&:under_siege)
    @window_open = WorldFortress::SIEGE_OPEN_HOUR..WorldFortress::SIEGE_CLOSE_HOUR
    @hour = Time.current.hour
  end
end

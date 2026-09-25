# frozen_string_literal: true

# Outdoor/world entry for Ashen Obelisk recall (bind stays at the building).
class WorldObelisksController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def create
    unless params[:obelisk_action].to_s == "recall"
      redirect_to world_path(obelisk_denied: 1),
        alert: I18n.t("game.buildings.obelisk_bad_action"),
        status: :see_other
      return
    end

    result = Game::World::ObeliskRecall.new(
      character: current_character,
      action: "recall"
    ).call
    if result.success
      redirect_to world_path, notice: result.message
    else
      redirect_to world_path(obelisk_denied: 1), alert: result.message, status: :see_other
    end
  end
end

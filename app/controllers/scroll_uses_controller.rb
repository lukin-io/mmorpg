# frozen_string_literal: true

# Targeted item use owns its ordered two-player lock boundary; the single-player
# Inventory around-action must not enclose this combat-entry transaction.
class ScrollUsesController < ApplicationController
  before_action :ensure_active_character!

  def create
    match = Game::Inventory::AttackScroll.new(character: current_character).call(
      action_key: params[:action_key], target_name: params[:target_name])
    redirect_to arena_match_path(match), status: :see_other
  rescue Game::Inventory::AttackScroll::Unavailable => error
    redirect_to inventory_path(category: "things", subcategory: "scrolls"),
      flash: {scroll_error: error.message}, status: :see_other
  end
end

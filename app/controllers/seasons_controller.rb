# frozen_string_literal: true

# Seasonal battle-pass FOMO surface (Mist-style retention + convenience VM track).
class SeasonsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  def show
    @season = Game::Seasons::Progress.new(character: current_character).snapshot
    @wallet = current_user.currency_wallet || current_user.create_currency_wallet!(nv_balance: 0)
    @shop_offers = Game::Seasons::Shop.offers
    @shop_bought_today = current_character.metadata.to_h
      .dig(Game::Seasons::Progress::META_KEY, "shop_bought", Time.current.utc.to_date.iso8601)
      .to_h
  end

  def unlock_premium
    result = Game::Seasons::Progress.new(character: current_character).unlock_premium!
    redirect_to season_path, status: :see_other, **flash_for(result)
  end

  def claim
    result = Game::Seasons::Progress.new(character: current_character).claim!(
      track: params[:track],
      level: params[:level]
    )
    redirect_to season_path, status: :see_other, **flash_for(result)
  end

  def buy_offer
    result = Game::Seasons::Shop.new(character: current_character, offer_key: params[:offer_key]).buy!
    redirect_to season_path, status: :see_other, **flash_for(result)
  end

  private

  def flash_for(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end

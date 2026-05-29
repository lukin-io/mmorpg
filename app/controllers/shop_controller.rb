# frozen_string_literal: true

class ShopController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :ensure_shop_access!
  before_action :set_inventory_and_wallet

  def show
    load_shop
  end

  def buy
    item_template = Game::Shop::Catalog.buyable_template(params[:item_template_id])
    result = Game::Shop::Purchase.new(
      character: current_character,
      item_template:,
      quantity: shop_quantity
    ).call

    redirect_to shop_return_path, flash_for(result)
  end

  def sell
    inventory_item = @inventory.inventory_items.find_by(id: params[:item_id])
    result = Game::Shop::Sale.new(
      character: current_character,
      inventory_item:,
      quantity: shop_quantity
    ).call

    redirect_to shop_return_path(mode: "sell"), flash_for(result)
  end

  private

  def load_shop
    @catalog = Game::Shop::Catalog.new(character: current_character, params:)
    @mode = @catalog.mode
    @category = @catalog.category
    @shop_items = @catalog.items
    @sell_items = @catalog.sell_items(@inventory)
  end

  def set_inventory_and_wallet
    @inventory = current_character.inventory || current_character.create_inventory!
    @wallet = current_user.currency_wallet || current_user.create_currency_wallet!(nv_balance: 0)
  end

  def ensure_shop_access!
    position = current_character.position
    unless position&.zone&.city? && shop_hotspot_available?(position.zone)
      redirect_to world_path, alert: "Лавка доступна только из городского здания."
    end
  end

  def shop_hotspot_available?(zone)
    CityHotspot.for_zone(zone).any? do |hotspot|
      feature_key = hotspot.action_params.to_h["feature"] || hotspot.key
      feature_key == "shop" && hotspot.can_interact?(current_character)
    end
  end

  def shop_quantity
    params[:quantity].to_i.clamp(1, 99)
  end

  def shop_return_path(overrides = {})
    allowed = params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price).to_h
    shop_path(allowed.merge(overrides).compact_blank)
  end

  def flash_for(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end

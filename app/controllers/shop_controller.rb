# frozen_string_literal: true

class ShopController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :ensure_shop_access!
  before_action :set_inventory_and_wallet

  def show
    load_shop
    Game::World::ResumeContext.new(character: current_character).remember_shop!(
      params: shop_resume_params
    )
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
    @sell_items = @catalog.sell_items(@inventory, loaded_items: @shop_inventory_items)
  end

  def set_inventory_and_wallet
    @inventory = current_character.inventory || current_character.create_inventory!
    @shop_inventory_items = @inventory.inventory_items.includes(:item_template).to_a
    @wallet = current_user.currency_wallet || current_user.create_currency_wallet!(nv_balance: 0)
  end

  def ensure_shop_access!
    unless Game::World::ResumeContext.new(character: current_character).shop_available?
      redirect_to world_path, alert: "Shop is only available from an accessible trading location."
    end
  end

  def shop_quantity
    params[:quantity].to_i.clamp(1, 99)
  end

  def shop_return_path(overrides = {})
    allowed = params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price).to_h
    shop_path(allowed.merge(overrides).compact_blank)
  end

  def shop_resume_params
    params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price).to_h.merge(
      "mode" => @mode,
      "category" => @category
    )
  end

  def flash_for(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end

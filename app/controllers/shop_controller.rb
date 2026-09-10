# frozen_string_literal: true

class ShopController < ApplicationController
  include CurrentCharacterContext
  include OutdoorActionAvailability

  before_action :ensure_active_character!
  around_action :with_available_outdoor_actions
  before_action :ensure_shop_access!
  before_action :set_inventory_and_wallet

  rescue_from Game::Shop::TradeOffers::Unavailable do |error|
    redirect_to world_path, alert: error.message
  end

  def show
    resume_context = Game::World::ResumeContext.new(character: current_character)
    resume_context.remember_shop!(params: shop_resume_params)
    @shop_parent_location = resume_context.shop_parent_location
    @shop_account = Game::Shop::Location.new(character: current_character).call.account
    load_shop
    offers = Game::Shop::TradeOffers.new(character: current_character).issue(
      buy_items: %w[buy licenses].include?(@mode) ? @shop_items : [],
      sell_items: @mode == "sell" ? @sell_items : []
    )
    @shop_buy_offers = offers.fetch(:buy)
    @shop_sell_offers = offers.fetch(:sell)
    prepare_presence_context
  end

  def buy
    item_template = Game::Shop::Catalog.buyable_template(params[:item_template_id])
    result = Game::Shop::Purchase.new(
      character: current_character,
      item_template:,
      action_key: params[:action_key],
      quantity: shop_quantity
    ).call

    redirect_to shop_return_path, flash_for(result)
  end

  def sell
    inventory_item = @inventory.inventory_items.find_by(id: params[:item_id])
    result = Game::Shop::Sale.new(
      character: current_character,
      inventory_item:,
      action_key: params[:action_key],
      quantity: shop_quantity
    ).call

    redirect_to shop_return_path(mode: "sell"), flash_for(result)
  end

  private

  def load_shop
    @shop_license_rules = Game::Shop::LicenseRules.new(character: current_character,
      active_licenses: CharacterLicense.where(character: current_character).active_at(Time.current).to_a)
    @catalog = Game::Shop::Catalog.new(character: current_character, shop_account: @shop_account, params:)
    @mode = @catalog.mode
    @category = @catalog.category
    @shop_items = @catalog.items
    @sell_items = @catalog.sell_items(@inventory, loaded_items: @shop_inventory_items)
    template_ids = (@shop_items.map(&:id) + @sell_items.map(&:item_template_id)).uniq
    @shop_stocks = @shop_account&.shop_stocks&.where(item_template_id: template_ids)&.index_by(&:item_template_id) || {}
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
    params.fetch(:quantity, 1)
  end

  def shop_return_path(overrides = {})
    allowed = params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price).to_h
    shop_path(allowed.merge(overrides).compact_blank)
  end

  def shop_resume_params
    params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price).to_h
  end

  def flash_for(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end

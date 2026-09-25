# frozen_string_literal: true

# Character Trade Hub — supply, scrolls, auction, exchange, premium without city trip.
class TradeHubController < ApplicationController
  include CurrentCharacterContext

  TABS = %w[supply scrolls auction exchange premium].freeze

  before_action :ensure_active_character!
  layout "game"

  def show
    @tab = TABS.include?(params[:tab].to_s) ? params[:tab].to_s : "supply"
    Game::Professions::Templates.ensure_craft_items!
    @wallet = current_character.user.currency_wallet || current_character.user.create_currency_wallet!
    @nv = @wallet.nv_balance.to_i
    @vm = @wallet.veil_marks.to_i
    case @tab
    when "supply"
      @supply_offers = supply_offers
    when "scrolls"
      @scroll_keys = Game::Shop::PremiumScrollPurchase::OFFERINGS.keys.reject { |k| k == "combat_trauma_scroll" }
      @preferred = current_character.metadata.to_h["preferred_assault_scroll_kind"].presence || "normal"
    when "auction"
      @listings = AuctionListing.open.not_expired.craft_goods.includes(:seller_character, :item_template).order(created_at: :desc).limit(50)
      inventory_items = current_character.inventory&.inventory_items&.where(equipped: false)&.includes(:item_template)&.order(:id)&.limit(100) || []
      @listable_items = inventory_items.select { |row| AuctionListing.listable_template?(row.item_template) }.first(40)
    when "exchange"
      @offers = CurrencyExchangeOffer.open.includes(:seller).order(created_at: :desc).limit(50)
    when "premium"
      @premium_offers = Game::Shop::PremiumScrollPurchase::OFFERINGS
      @premium_plans = Game::Shop::PremiumPass.plans
      @premium_perks = Game::Shop::PremiumPass.perks_for(current_user)
    end
  end

  def buy_supply
    key = params[:item_key].to_s
    offer = supply_offers[key]
    return redirect_to(trade_hub_path(tab: "supply"), alert: I18n.t("game.trade_hub.unknown_offer")) unless offer

    template = ItemTemplate.find_by(key:)
    return redirect_to(trade_hub_path(tab: "supply"), alert: I18n.t("game.trade_hub.missing_template")) unless template

    price = offer.fetch(:price)
    wallet = current_character.user.currency_wallet
    if wallet.nv_balance.to_d < price
      return redirect_to(trade_hub_path(tab: "supply"), alert: I18n.t("game.shop.not_enough_nv"))
    end

    ActiveRecord::Base.transaction do
      wallet.adjust!(
        amount: -price,
        reason: "trade_hub.supply",
        metadata: {"item_key" => key, "character_id" => current_character.id}
      )
      inventory = current_character.inventory || current_character.create_inventory!
      Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: offer.fetch(:quantity, 1))
    end

    redirect_to trade_hub_path(tab: "supply"), notice: I18n.t("game.trade_hub.bought", name: template.name), status: :see_other
  rescue Game::Inventory::Manager::CapacityExceededError => e
    redirect_to trade_hub_path(tab: "supply"), alert: e.message, status: :see_other
  end

  def buy_scroll
    result = Game::Shop::PremiumScrollPurchase.new(
      character: current_character,
      item_key: params[:item_key]
    ).call
    redirect_to trade_hub_path(tab: "scrolls"),
      status: :see_other,
      **(result.success ? {notice: result.message} : {alert: result.message})
  end

  def list_auction
    item = current_character.inventory&.inventory_items&.find_by(id: params[:inventory_item_id], equipped: false)
    price = params[:price_nv].to_d
    qty = [params[:quantity].to_i, 1].max
    return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_missing_item")) unless item
    unless AuctionListing.listable_template?(item.item_template)
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_craft_only"))
    end
    return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_bad_price")) unless price.positive?
    return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_bad_qty")) if qty > item.quantity
    if AuctionListing.slots_full?(current_character)
      limit = AuctionListing.open_slot_limit_for(current_character)
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_slots_full", limit:))
    end

    fee = AuctionListing::LISTING_FEE_NV
    wallet = current_character.user.currency_wallet
    if wallet.nv_balance.to_d < fee
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_need_fee", fee: fee.to_i))
    end

    ActiveRecord::Base.transaction do
      wallet.adjust!(
        amount: -fee,
        reason: "trade_hub.auction_fee",
        metadata: {"item_template_id" => item.item_template_id}
      )
      Game::Inventory::Manager.new(inventory: current_character.inventory).remove_item!(
        item_template: item.item_template,
        quantity: qty
      )
      AuctionListing.create!(
        seller_character: current_character,
        item_template: item.item_template,
        quantity: qty,
        price_nv: price,
        status: "open",
        metadata: {"listed_from_item_id" => item.id}
      )
    end

    redirect_to trade_hub_path(tab: "auction"), notice: I18n.t("game.trade_hub.auction_listed"), status: :see_other
  rescue Game::Inventory::Manager::InventoryUnderflowError => e
    redirect_to trade_hub_path(tab: "auction"), alert: e.message, status: :see_other
  end

  def cancel_auction
    listing = AuctionListing.lock.find_by(id: params[:listing_id], status: "open")
    return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_gone")) unless listing

    ActiveRecord::Base.transaction do
      listing.cancel_by!(current_character)
      inventory = current_character.inventory || current_character.create_inventory!
      Game::Inventory::Manager.new(inventory:).add_item!(
        item_template: listing.item_template,
        quantity: listing.quantity
      )
    end

    redirect_to trade_hub_path(tab: "auction"), notice: I18n.t("game.trade_hub.auction_cancelled"), status: :see_other
  rescue ArgumentError => e
    redirect_to trade_hub_path(tab: "auction"), alert: e.message, status: :see_other
  end

  def buy_auction
    listing = AuctionListing.lock.find_by(id: params[:listing_id], status: "open")
    return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_gone")) unless listing
    if listing.expired?
      listing.update!(status: "cancelled")
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_expired"))
    end
    if listing.seller_character_id == current_character.id
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.trade_hub.auction_own"))
    end

    buyer_wallet = current_character.user.currency_wallet
    seller_wallet = listing.seller_character.user.currency_wallet
    price = listing.price_nv.to_d
    if buyer_wallet.nv_balance.to_d < price
      return redirect_to(trade_hub_path(tab: "auction"), alert: I18n.t("game.shop.not_enough_nv"))
    end

    ActiveRecord::Base.transaction do
      buyer_wallet.adjust!(amount: -price, reason: "trade_hub.auction_buy", metadata: {"listing_id" => listing.id})
      seller_wallet.adjust!(amount: price, reason: "trade_hub.auction_sell", metadata: {"listing_id" => listing.id})
      inventory = current_character.inventory || current_character.create_inventory!
      Game::Inventory::Manager.new(inventory:).add_item!(item_template: listing.item_template, quantity: listing.quantity)
      listing.update!(status: "sold", buyer_character: current_character)
    end

    redirect_to trade_hub_path(tab: "auction"), notice: I18n.t("game.trade_hub.auction_bought"), status: :see_other
  end

  def create_exchange
    give = params[:give_currency].to_s
    want = params[:want_currency].to_s
    give_amount = params[:give_amount].to_d
    want_amount = params[:want_amount].to_d
    offer = CurrencyExchangeOffer.new(
      seller: current_user,
      give_currency: give,
      want_currency: want,
      give_amount:,
      want_amount:,
      status: "open"
    )
    unless offer.valid?
      return redirect_to(trade_hub_path(tab: "exchange"), alert: offer.errors.full_messages.to_sentence)
    end

    wallet = current_user.currency_wallet
    available = give == "nv" ? wallet.nv_balance.to_d : wallet.veil_marks.to_d
    if available < give_amount
      return redirect_to(trade_hub_path(tab: "exchange"), alert: I18n.t("game.trade_hub.exchange_funds"))
    end

    ActiveRecord::Base.transaction do
      if give == "nv"
        wallet.adjust!(amount: -give_amount, reason: "trade_hub.exchange_hold", metadata: {"side" => "give"})
      else
        wallet.adjust_veil_marks!(amount: -give_amount, reason: "trade_hub.exchange_hold", metadata: {"side" => "give"})
      end
      offer.save!
    end

    redirect_to trade_hub_path(tab: "exchange"), notice: I18n.t("game.trade_hub.exchange_created"), status: :see_other
  end

  def fill_exchange
    offer = CurrencyExchangeOffer.lock.find_by(id: params[:offer_id], status: "open")
    return redirect_to(trade_hub_path(tab: "exchange"), alert: I18n.t("game.trade_hub.exchange_gone")) unless offer
    if offer.seller_id == current_user.id
      return redirect_to(trade_hub_path(tab: "exchange"), alert: I18n.t("game.trade_hub.exchange_own"))
    end

    buyer_wallet = current_user.currency_wallet
    seller_wallet = offer.seller.currency_wallet
    want_available = offer.want_currency == "nv" ? buyer_wallet.nv_balance.to_d : buyer_wallet.veil_marks.to_d
    if want_available < offer.want_amount.to_d
      return redirect_to(trade_hub_path(tab: "exchange"), alert: I18n.t("game.trade_hub.exchange_funds"))
    end

    ActiveRecord::Base.transaction do
      debit_currency!(buyer_wallet, offer.want_currency, offer.want_amount, "trade_hub.exchange_fill_pay")
      credit_currency!(buyer_wallet, offer.give_currency, offer.give_amount, "trade_hub.exchange_fill_get")
      credit_currency!(seller_wallet, offer.want_currency, offer.want_amount, "trade_hub.exchange_fill_receive")
      offer.update!(status: "filled")
    end

    redirect_to trade_hub_path(tab: "exchange"), notice: I18n.t("game.trade_hub.exchange_filled"), status: :see_other
  end

  def buy_premium_pass
    result = Game::Shop::PremiumPass.new(user: current_user).purchase!(plan_key: params[:plan_key])
    redirect_to trade_hub_path(tab: "premium"),
      status: :see_other,
      **(result.success ? {notice: result.message} : {alert: result.message})
  end

  def claim_premium_stipend
    result = Game::Shop::PremiumPass.new(user: current_user).claim_daily_stipend!
    redirect_to trade_hub_path(tab: "premium"),
      status: :see_other,
      **(result.success ? {notice: result.message} : {alert: result.message})
  end

  private

  def supply_offers
    bandage_price = 18
    if Game::Seasons::Catalog.active?
      # Soft convenience sink: combat players without craft pay more for bandages.
      bandage_price = (bandage_price * 1.2).ceil
    end

    {
      "ashen_bait" => {price: 8, quantity: 5},
      "ashen_bandage" => {price: bandage_price, quantity: 1},
      "ash_herb" => {price: 10, quantity: 2},
      "ashen_hatchet" => {price: 55, quantity: 1},
      "ashen_sickle" => {price: 50, quantity: 1},
      "ashen_fishing_rod" => {price: 70, quantity: 1},
      "ashen_rod_ash" => {price: 150, quantity: 1},
      "ashen_rod_salt" => {price: 280, quantity: 1},
      "ashen_rod_veil" => {price: 480, quantity: 1},
      "hook_worm" => {price: 5, quantity: 10},
      "hook_bloodworm" => {price: 8, quantity: 10},
      "hook_dough" => {price: 6, quantity: 10},
      "hook_ember_fly" => {price: 10, quantity: 10},
      "hook_crumb" => {price: 4, quantity: 10}
    }
  end

  def debit_currency!(wallet, currency, amount, reason)
    if currency == "nv"
      wallet.adjust!(amount: -amount, reason:, metadata: {})
    else
      wallet.adjust_veil_marks!(amount: -amount, reason:, metadata: {})
    end
  end

  def credit_currency!(wallet, currency, amount, reason)
    if currency == "nv"
      wallet.adjust!(amount: amount, reason:, metadata: {})
    else
      wallet.adjust_veil_marks!(amount: amount, reason:, metadata: {})
    end
  end
end

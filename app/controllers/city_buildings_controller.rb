# frozen_string_literal: true

class CityBuildingsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :load_building
  around_action :with_building_access

  def show
    Game::World::ResumeContext.new(character: current_character).remember_city_building!(
      building_key: params[:building_key]
    )
    @building = Game::World::CityBuildingCatalog.fetch(@building_key, zone: @position.zone)
    if @building_key == "airship_station"
      Game::World::AshenAirshipStations.ensure!
      @airship_routes = Game::World::AirshipTravel.new(character: current_character).station_routes!
    end
    if @building_key == "workshop"
      Game::Professions::Templates.ensure_craft_items!
      @profession_recipes = Game::Professions::Catalog.recipes_for_building("workshop")
      @tar_smith_skill = current_character.metadata.to_h.dig("profession_skills", "tar_smith").to_i
      @repairable_items = current_character.inventory&.inventory_items
        &.includes(:item_template)
        &.select { |row|
          max = row.item_template&.durability_max.to_i
          max.positive? && row.current_durability.to_i < max
        }
        &.first(20) || []
    end
    if @building_key == "junk_dealer" || @building_key == "market"
      Game::Professions::Templates.ensure_craft_items!
      @junk_offers = Game::Shop::JunkBuyback.offer_rows_for(current_character)
    end
    if @building_key == "market"
      @stall_listings = Game::Shop::StallListing.open_rows
      @stall_lease = Game::Shop::StallRent.active_for(current_character)
      @stall_mass_used = @stall_lease ? Game::Shop::StallListing.used_mass_for(current_character) : 0
      stall_items = current_character.inventory&.inventory_items&.where(equipped: false)&.includes(:item_template)&.order(:id)&.limit(100) || []
      @stall_listable = stall_items.select { |row| AuctionListing.listable_template?(row.item_template) }.first(40)
    end
    if @building_key == "hospital"
      Game::Professions::Templates.ensure_craft_items!
      @injury_summary = Game::Combat::InjuryState.new(character: current_character).summary
      @profession_recipes = Game::Professions::Catalog.recipes_for_building("hospital")
      @ash_healer_skill = current_character.metadata.to_h.dig("profession_skills", "ash_healer").to_i
      wallet = current_user.currency_wallet || current_user.create_currency_wallet!(nv_balance: 0)
      @veil_marks = wallet.veil_marks.to_i
      @wallet_nv = wallet.nv_balance.to_i
      @premium_offers = Game::Shop::PremiumScrollPurchase::OFFERINGS
    end
    if @building_key == "bank"
      wallet = current_user.currency_wallet || current_user.create_currency_wallet!(nv_balance: 0)
      @bank_wallet_nv = wallet.nv_balance.to_i
      @bank_vault_nv = Game::World::BankVault.balance_for(current_character)
      @veil_marks = wallet.veil_marks.to_i
      @bank_item = Game::World::BankItemLocker.stored_for(current_character)
      @bank_deposit_options = current_character.inventory&.inventory_items
        &.where(equipped: false)
        &.includes(:item_template)
        &.select { |row| row.quantity.to_i.positive? }
        &.map { |row| [row.item_template.display_name, row.item_template.key, row.quantity.to_i] }
        &.uniq { |(_, key, _)| key } || []
    end
    if @building_key == "post"
      @post_note = Game::World::PostOfficeNote.current_for(current_character)
      @post_inbox = Game::World::PostOfficeMail.inbox_for(current_character)
    end
    if @building_key == "auction"
      Game::Professions::Templates.ensure_craft_items!
      @auction_listings = AuctionListing.open.craft_goods.includes(:seller_character, :item_template).order(created_at: :desc).limit(50)
      auction_items = current_character.inventory&.inventory_items&.where(equipped: false)&.includes(:item_template)&.order(:id)&.limit(100) || []
      @auction_listable = auction_items.select { |row| AuctionListing.listable_template?(row.item_template) }.first(40)
    end
    if @building_key == "numismatics"
      Game::Professions::Templates.ensure_craft_items!
      @numismatics_rows = Game::World::ResourceExchange.offer_rows_for(current_character)
    end
    if @building_key == "clan_hall"
      @sector_war_rows = Game::World::SectorWarBoard.new.call
    end
    if @building_key == "souvenir_shop"
      Game::Professions::Templates.ensure_craft_items!
    end
    if @building_key == "obelisk"
      @obelisk_bound = Game::World::ObeliskRecall.bound_for(current_character)
    end
    if @building_key == "guard_tower"
      @guard_routes = Game::World::GuardTowerRoutes.new(character: current_character).call
    end
    prepare_presence_context
  end

  def rest
    case @building_key
    when "hospital"
      result = Game::World::HospitalRest.new(character: current_character).call
      target_key = "hospital"
    when "tavern"
      result = Game::World::TavernRest.new(character: current_character).call
      target_key = "tavern"
    else
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.rest_unavailable"), status: :see_other
      return
    end

    extra = result.success ? {} : {rest_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path(target_key, **extra), **flash_opts
  end

  def craft
    unless %w[workshop hospital].include?(@building_key)
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.professions.workshop_only"), status: :see_other
      return
    end

    recipe = Game::Professions::Catalog.recipe(params[:recipe_key])
    profession = recipe && Game::Professions::Catalog.professions[recipe["profession"].to_s]
    if profession && profession["building_key"].to_s != @building_key
      redirect_to city_building_path(@building_key, craft_denied: 1),
        alert: I18n.t("game.professions.wrong_building") and return
    end

    result = Game::Professions::Craft.new(
      character: current_character,
      recipe_key: params[:recipe_key]
    ).call
    extra = result.success ? {} : {craft_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path(@building_key, **extra), **flash_opts
  end

  def repair
    unless @building_key == "workshop"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.professions.workshop_only"), status: :see_other
      return
    end

    result = Game::Professions::AshenRepair.new(
      character: current_character,
      inventory_item_id: params[:inventory_item_id]
    ).call
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("workshop", repair: result.success ? 1 : 0), **flash_opts
  end

  def recraft
    unless @building_key == "workshop"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.professions.workshop_only"), status: :see_other
      return
    end

    result = Game::Professions::Recraft.new(
      character: current_character,
      inventory_item_id: params[:inventory_item_id]
    ).call
    extra = result.success ? {} : {recraft_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("workshop", **extra), **flash_opts
  end

  def buy_premium
    unless @building_key == "hospital"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.hospital_only"), status: :see_other
      return
    end

    result = Game::Shop::PremiumScrollPurchase.new(
      character: current_character,
      item_key: params[:item_key]
    ).call
    redirect_hospital(result)
  end

  def topup_vm
    unless @building_key == "hospital"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.hospital_only"), status: :see_other
      return
    end

    result = Game::Shop::VeilMarksTopUp.new(character: current_character, amount: params[:amount]).call
    redirect_hospital(result)
  end

  def traumatologist
    unless @building_key == "hospital"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.hospital_only"), status: :see_other
      return
    end

    result = Game::Shop::TraumatologistClearance.new(character: current_character).call
    redirect_hospital(result)
  end

  def bless
    unless @building_key == "temple"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.temple_only"), status: :see_other
      return
    end

    result = Game::World::TempleBlessing.new(character: current_character).call
    extra = result.success ? {} : {temple_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("temple", **extra), **flash_opts
  end

  def bank
    unless @building_key == "bank"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.bank_only"), status: :see_other
      return
    end

    result = Game::World::BankVault.new(
      character: current_character,
      amount: params[:amount],
      action: params[:bank_action]
    ).call
    redirect_bank(result)
  end

  def bank_item
    unless @building_key == "bank"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.bank_only"), status: :see_other
      return
    end

    result = Game::World::BankItemLocker.new(
      character: current_character,
      action: params[:bank_item_action],
      item_key: params[:item_key],
      quantity: params[:quantity]
    ).call
    redirect_bank(result)
  end

  def post
    unless @building_key == "post"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.post_only"), status: :see_other
      return
    end

    result = case params[:post_action].to_s
    when "clear"
      Game::World::PostOfficeNote.new(character: current_character).clear!
    when "send_mail"
      Game::World::PostOfficeMail.new(
        character: current_character,
        body: params[:body],
        recipient_name: params[:recipient_name]
      ).send!
    when "clear_inbox"
      Game::World::PostOfficeMail.new(character: current_character).clear_inbox!
    else
      Game::World::PostOfficeNote.new(character: current_character, body: params[:body]).save!
    end
    extra = result.success ? {} : {post_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("post", **extra), **flash_opts
  end

  def list_auction
    unless @building_key == "auction"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.auction_only"), status: :see_other
      return
    end

    item = current_character.inventory&.inventory_items&.find_by(id: params[:inventory_item_id], equipped: false)
    price = params[:price_nv].to_d
    qty = [params[:quantity].to_i, 1].max
    return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_missing_item")) unless item
    unless AuctionListing.listable_template?(item.item_template)
      return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_craft_only"))
    end
    return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_bad_price")) unless price.positive?
    return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_bad_qty")) if qty > item.quantity
    if AuctionListing.slots_full?(current_character)
      limit = AuctionListing.open_slot_limit_for(current_character)
      return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_slots_full", limit:))
    end

    ActiveRecord::Base.transaction do
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
        metadata: {"listed_from" => "city_auction", "listed_from_item_id" => item.id}
      )
    end

    redirect_to city_building_path("auction"), notice: I18n.t("game.trade_hub.auction_listed"), status: :see_other
  rescue Game::Inventory::Manager::InventoryUnderflowError => e
    redirect_to city_building_path("auction"), alert: e.message, status: :see_other
  end

  def buy_auction
    unless @building_key == "auction"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.auction_only"), status: :see_other
      return
    end

    listing = AuctionListing.lock.find_by(id: params[:listing_id], status: "open")
    return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_gone")) unless listing
    if listing.seller_character_id == current_character.id
      return redirect_to(city_building_path("auction"), alert: I18n.t("game.trade_hub.auction_own"))
    end

    buyer_wallet = current_character.user.currency_wallet
    seller_wallet = listing.seller_character.user.currency_wallet
    price = listing.price_nv.to_d
    if buyer_wallet.nv_balance.to_d < price
      return redirect_to(city_building_path("auction"), alert: I18n.t("game.shop.not_enough_nv"))
    end

    ActiveRecord::Base.transaction do
      buyer_wallet.adjust!(amount: -price, reason: "city.auction_buy", metadata: {"listing_id" => listing.id})
      seller_wallet.adjust!(amount: price, reason: "city.auction_sell", metadata: {"listing_id" => listing.id})
      inventory = current_character.inventory || current_character.create_inventory!
      Game::Inventory::Manager.new(inventory:).add_item!(item_template: listing.item_template, quantity: listing.quantity)
      listing.update!(status: "sold", buyer_character: current_character)
    end

    redirect_to city_building_path("auction"), notice: I18n.t("game.trade_hub.auction_bought"), status: :see_other
  end

  def souvenir
    unless @building_key == "souvenir_shop"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.souvenir_only"), status: :see_other
      return
    end

    result = Game::World::SouvenirPurchase.new(
      character: current_character,
      item_key: params[:item_key]
    ).call
    extra = result.success ? {} : {souvenir_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("souvenir_shop", **extra), **flash_opts
  end

  def obelisk
    unless @building_key == "obelisk"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.obelisk_only"), status: :see_other
      return
    end

    result = Game::World::ObeliskRecall.new(
      character: current_character,
      action: params[:obelisk_action]
    ).call
    if result.success
      if params[:obelisk_action].to_s == "recall"
        redirect_to world_path, notice: result.message
      else
        redirect_to city_building_path("obelisk"), notice: result.message
      end
    else
      redirect_to city_building_path("obelisk", obelisk_desk_denied: 1), alert: result.message
    end
  end

  def law
    unless @building_key == "law_abode"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.law_only"), status: :see_other
      return
    end

    result = Game::World::LawAlignmentPledge.new(
      character: current_character,
      alignment: params[:alignment]
    ).call
    extra = result.success ? {} : {law_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("law_abode", **extra), **flash_opts
  end

  def numismatics
    unless @building_key == "numismatics"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.numismatics_only"), status: :see_other
      return
    end

    result = Game::World::ResourceExchange.new(
      character: current_character,
      item_key: params[:item_key],
      quantity: params[:quantity],
      mode: :sell
    ).call
    extra = result.success ? {} : {numismatics_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("numismatics", **extra), **flash_opts
  end

  def sell
    unless @building_key == "junk_dealer"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.junk_only"), status: :see_other
      return
    end

    result = Game::Shop::JunkBuyback.new(
      character: current_character,
      item_key: params[:item_key],
      quantity: params[:quantity]
    ).call
    extra = result.success ? {} : {junk_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("junk_dealer", **extra), **flash_opts
  end

  def rent_stall
    unless @building_key == "market"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.market_only"), status: :see_other
      return
    end

    result = Game::Shop::StallRent.new(
      character: current_character,
      stall_name: params[:stall_name]
    ).call
    extra = result.success ? {} : {stall_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("market", **extra), **flash_opts
  end

  def list_stall
    unless @building_key == "market"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.market_only"), status: :see_other
      return
    end

    result = Game::Shop::StallListing.new(
      character: current_character,
      inventory_item_id: params[:inventory_item_id],
      quantity: params[:quantity],
      price_nv: params[:price_nv],
      featured: params[:featured]
    ).list!
    extra = result.success ? {} : {stall_listing_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("market", **extra), **flash_opts
  end

  def buy_stall
    unless @building_key == "market"
      redirect_to world_path(building_denied: 1), alert: I18n.t("game.buildings.market_only"), status: :see_other
      return
    end

    result = Game::Shop::StallListing.new(
      character: current_character,
      listing_id: params[:listing_id]
    ).buy!
    extra = result.success ? {} : {stall_listing_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("market", **extra), **flash_opts
  end

  private

  def load_building
    @building_key = params[:building_key].to_s
    @building = Game::World::CityBuildingCatalog.fetch(@building_key)
    redirect_to(world_path(building_denied: 1), alert: I18n.t("game.flashes.building_not_found")) unless @building
  end

  # Entry changes saved room state. Revalidate and render under the same lock
  # as city movement so a concurrent relocation cannot admit a stale building.
  def with_building_access
    current_character.with_lock do
      ensure_building_access!
      unless performed?
        @position = current_character.position
        yield
      end
    end
  end

  def ensure_building_access!
    return if performed?
    return if Game::World::CityBuildingCatalog.accessible?(
      character: current_character,
      building_key: @building_key
    )

    redirect_to world_path(building_denied: 1), alert: I18n.t("game.flashes.building_district_required")
  end

  def redirect_bank(result)
    extra = result.success ? {} : {bank_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("bank", **extra), **flash_opts
  end

  def redirect_hospital(result)
    extra = result.success ? {} : {hospital_denied: 1}
    flash_opts = result.success ? {notice: result.message} : {alert: result.message}
    redirect_to city_building_path("hospital", **extra), **flash_opts
  end
end

# frozen_string_literal: true

# Renders an allowlisted interior linked from the character's persisted
# outdoor cell. Opening an interior never replaces or browser-owns the world
# coordinate.
class WorldLocationsController < ApplicationController
  include CurrentCharacterContext
  include OutdoorActionAvailability

  layout "game"

  before_action :ensure_active_character!
  around_action :with_available_outdoor_actions
  before_action :ensure_location_not_in_combat!
  before_action :load_location!

  def show
    Game::World::AshenMineGallery.ensure_lobby!(@building)
    @building.reload
    @in_mine_gallery = Game::World::AshenMineGallery.descended?(current_character, location_key: @building.location_key)
    requested = params[:section].presence
    requested = "gallery" if @in_mine_gallery && requested.blank? && @building.location_kind == "mine"
    @location_section = @building.location_section(requested)
    if requested.present? && !@location_section
      redirect_to world_location_path(@building.location_key), status: :see_other
      return
    end
    @location_features = @building.location_features
    @wallet = current_user.currency_wallet if @building.location_kind == "exchange"
    if @building.location_kind == "exchange"
      @exchange_category = params[:resource_type].presence
      @exchange_sell_rows = Game::World::ResourceExchange.offer_rows_for(current_character, category: @exchange_category)
      @exchange_buy_rows = Game::World::ResourceExchange.buy_catalog(category: @exchange_category)
      @exchange_storage = Game::World::ResourceExchange.storage_for(current_character)
      @exchange_storage_total = Game::World::ResourceExchange.storage_total(current_character)
    end
    @feature_offers_by_key = build_feature_offers.index_by { |offer| offer.metadata["hotspot_key"] }
    @gallery_state = current_character.metadata.to_h[Game::World::AshenMineGallery::META_KEY].to_h if @in_mine_gallery
    Game::World::ResumeContext.new(character: current_character).remember_world_location!(key: @building.location_key)
    prepare_presence_context
  end

  def exchange
    unless @building.location_kind == "exchange"
      redirect_to world_location_path(@building.location_key), alert: I18n.t("game.locations.exchange_wrong_lobby"), status: :see_other
      return
    end

    mode = params[:mode].to_s
    result = Game::World::ResourceExchange.new(
      character: current_character,
      item_key: params[:item_key],
      quantity: params[:quantity],
      mode:
    ).call
    section = %w[sell buy storage].include?(params[:section].to_s) ? params[:section] : "sell"
    target = world_location_path(@building.location_key, section:, resource_type: params[:resource_type].presence)
    if result.success
      redirect_to target, notice: result.message, status: :see_other
    else
      redirect_to target, alert: result.message, status: :see_other
    end
  end

  def descend
    Game::World::AshenMineGallery.ensure_lobby!(@building)
    result = Game::World::AshenMineGallery.new(character: current_character, building: @building).descend!
    if result.success
      redirect_to world_location_path(@building.location_key, section: "gallery"),
        notice: result.message, status: :see_other
    else
      redirect_to world_location_path(@building.location_key), alert: result.message, status: :see_other
    end
  end

  def ascend
    result = Game::World::AshenMineGallery.new(character: current_character, building: @building).ascend!
    if result.success
      redirect_to world_location_path(@building.location_key), notice: result.message, status: :see_other
    else
      redirect_to world_location_path(@building.location_key, section: "gallery"),
        alert: result.message, status: :see_other
    end
  end

  def gallery_dig
    result = Game::World::AshenMineGallery.new(character: current_character, building: @building).dig!
    target = world_location_path(@building.location_key, section: "gallery")
    if result.success
      redirect_to target, notice: result.message, status: :see_other
    else
      redirect_to target, alert: result.message, status: :see_other
    end
  end

  def open_feature
    authorize_world_action_offer!(params[:action_key])

    feature_key = params[:feature_key].to_s
    feature = @building.location_feature(feature_key)
    raise Game::World::AcceptAction::ActionViolationError, I18n.t("game.world.location_feature_unavailable") unless feature

    offer = Game::World::AcceptAction.new(
      character: current_character,
      action_key: params[:action_key],
      action_type: :open_location_feature,
      target: @building,
      position: @position
    ).call
    validate_feature_offer!(offer, feature)

    destination_path = location_feature_path(feature)
    if feature["action_type"] == "return_world"
      Game::World::ResumeContext.new(character: current_character).remember_world!
    end
    offer.complete!
    redirect_to destination_path, status: :see_other
  rescue Game::World::AcceptAction::ActionViolationError => e
    redirect_to Game::World::ResumeContext.new(character: current_character).resume_path,
      alert: e.message, status: :see_other
  end

  private

  def ensure_location_not_in_combat!
    active_match = current_character.arena_participations.joins(:arena_match)
      .merge(ArenaMatch.active).order(created_at: :desc).first&.arena_match
    redirect_to arena_match_path(active_match), status: :see_other if active_match
  end

  def load_location!
    @position = current_character.position
    @tile_state = if @position
      Game::World::TileStateResolver.new(character: current_character, position: @position).call
    end
    building = @tile_state&.building
    key = params[:key].to_s

    unless building&.location? && building.location_key == key && building.can_enter?(current_character)
      redirect_to world_path(location_denied: 1), alert: I18n.t("game.flashes.location_gone")
      return
    end

    @building = building
  end

  def build_feature_offers
    Game::World::ActionOfferBuilder.new(
      character: current_character,
      position: @position,
      tile_state: @tile_state,
      context: :location
    ).call
  end

  def validate_feature_offer!(offer, feature)
    metadata = offer.metadata.to_h
    matches = metadata["building_key"] == @building.building_key &&
      metadata["hotspot_key"] == feature.fetch("key") &&
      metadata["location_action_type"] == feature.fetch("action_type") &&
      metadata["feature"] == feature["feature"]
    return if matches

    offer.fail!(I18n.t("game.world.location_feature_mismatch"))
    raise Game::World::AcceptAction::ActionViolationError, I18n.t("game.world.location_feature_mismatch")
  end

  def location_feature_path(feature)
    return world_path if feature["action_type"] == "return_world"

    path = CityHotspot.feature_route(feature["feature"])
    return path if path.present?

    raise Game::World::AcceptAction::ActionViolationError, I18n.t("game.world.location_feature_unavailable")
  end
end

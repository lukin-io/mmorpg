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
    @location_section = @building.location_section(params[:section])
    if params[:section].present? && !@location_section
      redirect_to world_location_path(@building.location_key), status: :see_other
      return
    end
    @location_features = @building.location_features
    @wallet = current_user.currency_wallet if @building.location_kind == "exchange"
    @feature_offers_by_key = build_feature_offers.index_by { |offer| offer.metadata["hotspot_key"] }
    Game::World::ResumeContext.new(character: current_character).remember_world_location!(key: @building.location_key)
    prepare_presence_context
  end

  def open_feature
    authorize_world_action_offer!(params[:action_key])

    feature_key = params[:feature_key].to_s
    feature = @building.location_feature(feature_key)
    raise Game::World::AcceptAction::ActionViolationError, "Location feature is unavailable" unless feature

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
      redirect_to world_path, alert: "This location is no longer available."
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

    offer.fail!("Location feature does not match the offer")
    raise Game::World::AcceptAction::ActionViolationError, "Location feature does not match the offer"
  end

  def location_feature_path(feature)
    return world_path if feature["action_type"] == "return_world"

    path = CityHotspot.feature_route(feature["feature"])
    return path if path.present?

    raise Game::World::AcceptAction::ActionViolationError, "Location feature is unavailable"
  end
end

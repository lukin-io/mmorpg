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
      @airship_routes = Game::World::AirshipTravel.new(character: current_character).station_routes!
    end
    if @building_key == "hospital"
      @hospital_items = ItemTemplate.where(key: %w[beginner_healer_bag skilled_healer_bag experienced_healer_bag combat_first_aid_kit]).order(:base_price)
      @hospital_offers = Game::Shop::TradeOffers.new(character: current_character).issue(buy_items: @hospital_items)[:buy]
    end
    prepare_presence_context
  end

  def purchase
    item = ItemTemplate.find_by!(key: params[:item_key])
    result = Game::Shop::Purchase.new(character: current_character, item_template: item, action_key: params[:action_key]).call
    redirect_to city_building_path(building_key: "hospital"),
      **(result.success ? {notice: result.message} : {alert: result.message}), status: :see_other
  end

  private

  def load_building
    @building_key = params[:building_key].to_s
    @building = Game::World::CityBuildingCatalog.fetch(@building_key)
    redirect_to(world_path, alert: "City building not found.") unless @building
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

    redirect_to world_path, alert: "Enter this building from its current city node."
  end
end

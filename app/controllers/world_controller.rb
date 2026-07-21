# frozen_string_literal: true

require "ostruct"

# WorldController handles the main game world view, movement between tiles,
# and location-based interactions.
#
# The player sees either the captured city-node graph or the outdoor map.
#
# Usage:
#   GET /world              - Show current location
#   POST /world/move        - Move to adjacent tile
#   POST /world/enter_building - Enter a current-cell entrance
#   POST /world/perform_local_action - Perform a current-cell local action
class WorldController < ApplicationController
  include CurrentCharacterContext

  layout "game"

  MAP_RENDER_RADIUS = 3
  PLAYER_SORT_ORDERS = {
    "az" => {name: :asc},
    "za" => {name: :desc},
    "lvl-asc" => {level: :asc, name: :asc},
    "lvl-desc" => {level: :desc, name: :asc}
  }.freeze

  before_action :ensure_active_character!
  before_action :ensure_character_position!
  before_action :set_position

  def show
    # City zones render captured node actions instead of an outdoor grid.
    if city_zone?
      @zone = @position.zone
      prepare_city_view
    else
      prepare_overworld_view
    end

    Game::World::ResumeContext.new(character: current_character).remember_world!

    # Handle both HTML and Turbo Stream requests with full page render
    # Turbo Stream requests can come from redirects after building entry
    respond_to do |format|
      format.html do
        if city_zone?
          render "world/city_view"
        else
          render "world/show"
        end
      end
      format.turbo_stream do
        # For Turbo Stream requests (e.g., after enter_building redirect),
        # render full HTML page to avoid "Content missing"
        # Use formats: [:html] to find the .html.erb template
        if city_zone?
          render "world/city_view", formats: [:html], layout: "game"
        else
          render "world/show", formats: [:html], layout: "game"
        end
      end
    end
  end

  # GET /world/players
  # Refresh the compact location-scoped presence list without replacing the
  # world or city surface.
  def players
    @players_here = players_at_current_tile(sort: params[:sort])

    render partial: "shared/nl_players_list", layout: false
  end

  def move
    interruption = interrupt_world_action
    return respond_with_world_interruption(interruption) if interruption.interrupted?

    result = Game::Movement::AcceptMove.new(
      character: current_character,
      action_key: params[:action_key],
      target_x: params[:target_x],
      target_y: params[:target_y],
      direction: params[:direction]
    ).call

    @position = result.position.reload
    respond_to do |format|
      format.turbo_stream { render_map_update }
      format.html { redirect_to world_path, notice: "Move started." }
    end
  rescue Game::Movement::MovementViolationError,
    Game::World::StartNpcFight::FightViolationError => e
    respond_to do |format|
      format.turbo_stream { render_movement_error(e.message) }
      format.html { redirect_to world_path, alert: e.message }
    end
  end

  # POST /world/interact_hotspot
  # Accept a captured city transition, building, or gate offer.
  def interact_hotspot
    hotspot = CityHotspot.find_by(id: params[:hotspot_id], zone: @position.zone)
    return respond_with_city_action_error("Location not found.") unless hotspot

    service = Game::World::CityHotspotService.new(
      character: current_character,
      zone: @position.zone
    )

    result = nil
    ActiveRecord::Base.transaction do
      action_offer = accept_world_action!(hotspot.world_action_type, target: hotspot)
      result = service.interact!(hotspot.id)
      result.success ? action_offer.complete! : action_offer.fail!(result.message)
    end

    if result.success
      if result.redirect_url.present?
        mark_city_arena_entry!(result.hotspot)
        # Navigate to a documented implemented feature page.
        respond_to do |format|
          format.html { redirect_to result.redirect_url, notice: result.message }
          format.turbo_stream do
            flash[:notice] = result.message
            redirect_to result.redirect_url, status: :see_other
          end
        end
      elsif result.destination_zone.present?
        # Zone transition - redirect to reload the world view
        respond_to do |format|
          format.html { redirect_to world_path, notice: result.message }
          format.turbo_stream do
            flash[:notice] = result.message
            redirect_to world_path, status: :see_other
          end
        end
      else
        redirect_to world_path, notice: result.message
      end
    else
      respond_to do |format|
        format.html { redirect_to world_path, alert: result.message }
        format.turbo_stream { render_error(result.message) }
      end
    end
  rescue Game::World::AcceptAction::ActionViolationError => e
    respond_with_city_action_error(e.message)
  end

  # POST /world/enter_building
  # Enter a building at the current tile
  def enter_building
    building = TileBuilding.find_by(id: params[:building_id])

    unless building
      return respond_to do |format|
        format.html { redirect_to world_path, alert: "Building not found." }
        format.turbo_stream { render_error("Building not found.") }
      end
    end

    action_offer = nil
    interruption = nil
    result = nil

    ActiveRecord::Base.transaction do
      action_offer = accept_world_action!(:enter_building, target: building)
      interruption = interrupt_world_action

      if interruption.interrupted?
        action_offer.complete!
      else
        service = Game::World::TileBuildingService.new(
          character: current_character,
          zone: @position.zone.name,
          x: @position.x,
          y: @position.y
        )
        result = service.enter!
      end
    end

    return respond_with_world_interruption(interruption) if interruption.interrupted?

    respond_to do |format|
      if result.success
        action_offer.complete!
        # Always redirect after entering a building - the target zone may be a city
        # which requires the full city_view template instead of partial updates
        format.html { redirect_to world_path, notice: result.message }
        format.turbo_stream do
          # Redirect via Turbo - triggers full page navigation
          flash[:notice] = result.message
          redirect_to world_path, status: :see_other
        end
      else
        action_offer.fail!(result.message)
        format.html { redirect_to world_path, alert: result.message }
        format.turbo_stream { render_error(result.message) }
      end
    end
  rescue Game::World::AcceptAction::ActionViolationError,
    Game::World::StartNpcFight::FightViolationError => e
    respond_with_world_action_error(e.message)
  end

  # POST /world/perform_local_action
  # Accept a Neverlands-shaped current-cell action such as `look`.
  def perform_local_action
    tile = MapTileTemplate.find_by(id: params[:tile_id])
    return respond_with_world_action_error("Local action is no longer available.") unless tile

    local_action_type = params[:local_action_type].to_s
    world_action_type = MapTileTemplate.world_action_type_for(local_action_type)
    return respond_with_world_action_error("Local action is not supported.") unless world_action_type

    result = nil
    interruption = nil

    ActiveRecord::Base.transaction do
      action_offer = accept_world_action!(world_action_type, target: tile)
      result = Game::World::PerformLocalAction.new(
        character: current_character,
        tile:,
        local_action_type:
      ).call

      if result.success
        interruption = interrupt_world_action
        action_offer.complete!
      else
        action_offer.fail!(result.message)
      end
    end

    return respond_with_world_action_error(result.message) unless result.success

    return respond_with_world_interruption(interruption) if interruption&.interrupted?

    respond_to do |format|
      format.html { redirect_to world_path, notice: result.message }
      format.turbo_stream do
        flash[:notice] = result.message
        redirect_to world_path, status: :see_other
      end
    end
  rescue Game::World::AcceptAction::ActionViolationError,
    Game::World::StartNpcFight::FightViolationError => e
    respond_with_world_action_error(e.message)
  end

  private

  def interrupt_world_action(return_context: "world")
    Game::World::InterruptAction.new(
      character: current_character,
      return_context:
    ).call
  end

  def respond_with_world_interruption(interruption)
    respond_to do |format|
      format.html { redirect_to arena_match_path(interruption.match), alert: interruption.message }
      format.turbo_stream do
        flash[:alert] = interruption.message
        redirect_to arena_match_path(interruption.match), status: :see_other
      end
    end
  end

  # Check if the current zone is a captured city node.
  def city_zone?
    @position.zone.city?
  end

  # Set up data for city view rendering
  def prepare_city_view
    @city_service = Game::World::CityHotspotService.new(
      character: current_character,
      zone: @position.zone
    )
    @hotspots = @city_service.hotspots
    @world_action_offers = Game::World::CityActionOfferBuilder.new(
      character: current_character,
      position: @position,
      hotspots: @hotspots
    ).call
    @city_action_offers_by_hotspot_id = @world_action_offers.index_by(&:target_id)
    @players_here = players_at_current_tile
  end

  def prepare_overworld_view
    @movement_state = Game::Movement::MapState.new(character: current_character).call
    @position = @movement_state.position.reload
    @zone = @position.zone
    @active_movement = @movement_state.active_command
    @movement_destinations = @movement_state.destinations
    @movement_remaining_seconds = @active_movement&.remaining_seconds || 0
    @movement_cooldown = @movement_destinations.first&.travel_seconds ||
      @active_movement&.travel_seconds ||
      Game::Movement::TravelTime::BASE_TRAVEL_SECONDS

    @tile_state = @active_movement ? nil : Game::World::TileStateResolver.new(
      character: current_character,
      position: @position
    ).call
    @world_action_offers = @active_movement ? [] : Game::World::ActionOfferBuilder.new(
      character: current_character,
      position: @position,
      tile_state: @tile_state
    ).call

    @tile = current_tile
    @nearby_tiles = nearby_tiles_with_features
    @tile_building = tile_building_at_current_tile
    @players_here = players_at_current_tile
    @available_actions = available_actions
  end

  def ensure_character_position!
    return if current_character.position.present?

    # The captured Forpost Central Square is the only MVP spawn node.
    starter_node = Game::World::CityCatalog.node("city2_1")
    starter_zone = Zone.find_by(name: starter_node.fetch("zone_name"), location_type: "city")
    unless starter_zone
      return render "world/no_zones", status: :service_unavailable
    end

    spawn = starter_zone.spawn_points.default_entries.first
    unless spawn
      return render "world/no_zones", status: :service_unavailable
    end

    current_character.create_position!(
      zone: starter_zone,
      x: spawn.x,
      y: spawn.y,
      state: :active,
      last_turn_number: 0
    )
  end

  def set_position
    @position = current_character.position
  end

  def current_tile
    @tile_state&.tile || missing_tile(@position.x, @position.y)
  end

  def missing_tile(x, y)
    OpenStruct.new(
      x:,
      y:,
      terrain_type: @position.zone.location_type,
      walkable: @position.zone.outdoor?,
      passable: @position.zone.outdoor?,
      metadata: {"sparse_default" => true}
    )
  end

  def nearby_tiles_with_features
    zone = @position.zone
    x_range = ((@position.x - MAP_RENDER_RADIUS)..(@position.x + MAP_RENDER_RADIUS))
    y_range = ((@position.y - MAP_RENDER_RADIUS)..(@position.y + MAP_RENDER_RADIUS))
    templates = MapTileTemplate.in_zone(zone.name).in_area(x_range, y_range).index_by { |tile| [tile.x, tile.y] }
    buildings = TileBuilding.active.in_zone(zone.name)
      .where(x: x_range, y: y_range)
      .index_by { |building| [building.x, building.y] }

    y_range.map do |y|
      x_range.map do |x|
        in_bounds = x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)
        template = templates[[x, y]] if in_bounds
        tile = in_bounds ? (template || missing_tile(x, y)) : out_of_bounds_tile(x, y)
        metadata = (tile.metadata || {}).dup
        metadata = add_visible_tile_features(
          metadata,
          building: (buildings[[x, y]] if in_bounds)
        )

        OpenStruct.new(
          x:,
          y:,
          terrain_type: tile.terrain_type,
          walkable: tile.walkable,
          passable: tile.respond_to?(:passable) ? tile.passable : tile.walkable,
          metadata:
        )
      end
    end
  end

  def out_of_bounds_tile(x, y)
    OpenStruct.new(
      x:,
      y:,
      terrain_type: "outdoor",
      walkable: false,
      passable: false,
      metadata: {"out_of_bounds" => true}
    )
  end

  # Buildings are visible authored cell content. Outdoor NPC placement remains
  # server-only and is revealed only when its encounter interrupts an action.
  def add_visible_tile_features(metadata, building:)
    if building
      metadata["building"] = building.name
    end

    metadata
  end

  def available_actions
    actions = []

    return actions if @active_movement

    # Tile Building actions (enterable structures)
    tile_building = tile_building_at_current_tile
    if tile_building.present?
      actions << {
        type: :tile_building,
        building: tile_building,
        offer: offers_by_action("enter_building").first
      }
    end

    Array(@tile_state&.local_actions).each do |local_action|
      world_action_type = MapTileTemplate.world_action_type_for(local_action["type"])
      offer = offers_by_action(world_action_type).first
      next unless offer && @tile_state.tile

      actions << {
        type: :tile_local_action,
        local_action: {
          tile_id: @tile_state.tile.id,
          local_action_type: local_action["type"],
          source_id: local_action["source_id"],
          label: local_action["label"].presence ||
            MapTileTemplate.default_local_action_label(local_action["type"]),
          description: local_action["description"]
        },
        offer:
      }
    end

    actions
  end

  def tile_building_at_current_tile
    return @tile_building if defined?(@tile_building) && @tile_building
    return @tile_state.building_info if @tile_state

    # Get tile building info at current position (for display)
    service = Game::World::TileBuildingService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )
    service.building_info
  end

  def players_at_current_tile(sort: "az")
    order = PLAYER_SORT_ORDERS.fetch(sort.to_s, PLAYER_SORT_ORDERS.fetch("az"))

    Character
      .joins(:position)
      .where(character_positions: {
        zone_id: @position.zone_id,
        x: @position.x,
        y: @position.y,
        state: CharacterPosition.states.fetch("active")
      })
      .where.not(id: current_character.id)
      .order(order)
      .limit(10)
  end

  def render_map_update
    prepare_overworld_view

    render turbo_stream: [
      turbo_stream.update("game-map", partial: "world/map", locals: {
        position: @position,
        nearby_tiles: @nearby_tiles,
        zone: @zone,
        tile_data: {},
        movement_destinations: @movement_destinations,
        active_movement: @active_movement,
        movement_remaining_seconds: @movement_remaining_seconds
      }),
      turbo_stream.update("location-info", partial: "world/location_info", locals: {
        position: @position,
        tile: @tile,
        zone: @zone
      }),
      turbo_stream.update("available-actions", partial: "world/actions", locals: {
        available_actions: @available_actions,
        position: @position
      })
    ]
  end

  def render_error(message)
    render turbo_stream: turbo_stream.update(
      "flash",
      partial: "shared/flash",
      locals: {type: :alert, message: message}
    )
  end

  def offers_by_action(action_type)
    (@world_action_offers || []).select { |offer| offer.action_type == action_type }
  end

  def accept_world_action!(action_type, target:)
    authorize_world_action_offer!(params[:action_key])
    Game::World::AcceptAction.new(
      character: current_character,
      action_key: params[:action_key],
      action_type: action_type,
      target: target,
      position: @position
    ).call
  end

  def respond_with_world_action_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { render_movement_error(message) }
      format.json { render json: {success: false, message: message}, status: :unprocessable_entity }
    end
  end

  def respond_with_city_action_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { render_error(message) }
      format.json { render json: {success: false, message:}, status: :unprocessable_content }
    end
  end

  def render_movement_error(message)
    prepare_overworld_view

    render turbo_stream: [
      turbo_stream.update("flash", partial: "shared/flash", locals: {type: :alert, message: message}),
      turbo_stream.update("game-map", partial: "world/map", locals: {
        position: @position,
        nearby_tiles: @nearby_tiles,
        zone: @zone,
        tile_data: {},
        movement_destinations: @movement_destinations,
        active_movement: @active_movement,
        movement_remaining_seconds: @movement_remaining_seconds
      }),
      turbo_stream.update("available-actions", partial: "world/actions", locals: {
        available_actions: @available_actions,
        position: @position
      })
    ]
  end
end

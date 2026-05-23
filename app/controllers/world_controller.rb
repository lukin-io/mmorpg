# frozen_string_literal: true

require "ostruct"

# WorldController handles the main game world view, movement between tiles,
# and location-based interactions.
#
# The player sees either:
# - A location view (city, building interior) with NPCs and actions
# - An overworld map grid for movement between tiles
#
# Usage:
#   GET /world              - Show current location
#   POST /world/move        - Move to adjacent tile
#   POST /world/enter       - Enter a building
#   POST /world/exit        - Exit to overworld
#   POST /world/interact    - Interact with NPC/object
class WorldController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :ensure_character_position!
  before_action :set_position

  def show
    # City zones render an interactive illustrated view instead of tile grid
    if city_zone?
      @zone = @position.zone
      prepare_city_view
    else
      prepare_overworld_view
    end

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
          render "world/city_view", formats: [:html], layout: "application"
        else
          render "world/show", formats: [:html], layout: "application"
        end
      end
    end
  end

  def move
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
      format.html { redirect_to world_path, notice: "Переход начат." }
    end
  rescue Game::Movement::MovementViolationError => e
    respond_to do |format|
      format.turbo_stream { render_movement_error(e.message) }
      format.html { redirect_to world_path, alert: e.message }
    end
  end

  def enter
    location_key = params[:location_key]

    # Find the zone/building to enter (search by name, case-insensitive)
    target_zone = Zone.find_by("LOWER(name) = ?", location_key.to_s.downcase)

    if target_zone.nil?
      return redirect_to world_path, alert: "Локация не найдена."
    end

    spawn_point = target_zone.spawn_points.default_entries.first

    if spawn_point.nil?
      return redirect_to world_path, alert: "Точка входа не настроена."
    end

    # Move character to new zone
    @position.update!(
      zone: target_zone,
      x: spawn_point.x,
      y: spawn_point.y,
      last_action_at: Time.current
    )

    redirect_to world_path, notice: "Вход: #{target_zone.name}."
  end

  def exit_location
    current_zone = @position.zone
    exit_zone_name = current_zone.metadata&.dig("exit_to")
    exit_zone = Zone.find_by(name: exit_zone_name) if exit_zone_name.present?

    if exit_zone.nil?
      return redirect_to world_path, alert: "No exit available."
    end

    spawn_point = exit_zone.spawn_points.default_entries.first

    if spawn_point.nil?
      return redirect_to world_path, alert: "No exit entry point available."
    end

    @position.update!(
      zone: exit_zone,
      x: spawn_point.x,
      y: spawn_point.y,
      last_action_at: Time.current
    )

    redirect_to world_path, notice: "Выход: #{exit_zone.name}."
  end

  # POST /world/interact_hotspot
  # Interact with a city hotspot (building, exit, feature)
  def interact_hotspot
    service = Game::World::CityHotspotService.new(
      character: current_character,
      zone: @position.zone
    )

    result = service.interact!(params[:hotspot_id])

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
  end

  # POST /world/enter_building
  # Enter a building at the current tile
  def enter_building
    building = TileBuilding.find_by(id: params[:building_id])

    unless building
      return respond_to do |format|
        format.html { redirect_to world_path, alert: "Здание не найдено." }
        format.turbo_stream { render_error("Здание не найдено.") }
      end
    end

    action_offer = accept_world_action!(:enter_building, target: building)

    service = Game::World::TileBuildingService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )

    result = service.enter!

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
  rescue Game::World::AcceptAction::ActionViolationError => e
    respond_with_world_action_error(e.message)
  end

  private

  # Check if current zone is a city (renders illustrated view)
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
    @tile_npc = tile_npc_at_current_tile
    @tile_building = tile_building_at_current_tile
    @players_here = players_at_current_tile
    @available_actions = available_actions
  end

  def ensure_character_position!
    return if current_character.position.present?

    # Create initial position in starter city zone.
    starter_zone = Zone.find_by(location_type: "city")
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
    MapTileTemplate.find_by(
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    ) || missing_tile(@position.x, @position.y)
  end

  def missing_tile(x, y)
    OpenStruct.new(
      x:,
      y:,
      terrain_type: "unconfigured",
      walkable: false,
      passable: false,
      metadata: {"missing_template" => true}
    )
  end

  def nearby_tiles
    zone = @position.zone
    tiles = []

    # Prefetch all tiles in range for efficiency
    x_range = ([@position.x - 2, 0].max..[@position.x + 2, zone.width - 1].min)
    y_range = ([@position.y - 2, 0].max..[@position.y + 2, zone.height - 1].min)

    db_tiles = MapTileTemplate.in_zone(zone.name).in_area(x_range, y_range).index_by { |t| [t.x, t.y] }

    # Get 5x5 grid around player (or zone bounds)
    y_range.each do |y|
      row = []
      x_range.each do |x|
        tile = db_tiles[[x, y]] || missing_tile(x, y)
        row << tile
      end
      tiles << row unless row.empty?
    end

    tiles
  end

  def nearby_tiles_with_features
    zone = @position.zone
    tiles = []

    # Get 5x5 grid around player
    ((@position.y - 2)..(@position.y + 2)).each do |y|
      row = []
      ((@position.x - 2)..(@position.x + 2)).each do |x|
        next if x < 0 || y < 0 || x >= zone.width || y >= zone.height

        tile_template = MapTileTemplate.find_by(zone: zone.name, x: x, y: y)

        if tile_template
          # Use tile template but override with actual live NPC/building data
          metadata = tile_template.respond_to?(:metadata) ? (tile_template.metadata || {}).dup : {}
          metadata = add_live_tile_features(zone.name, x, y, metadata)

          row << OpenStruct.new(
            x: x,
            y: y,
            terrain_type: tile_template.respond_to?(:terrain_type) ? tile_template.terrain_type : zone.location_type,
            walkable: tile_template.respond_to?(:walkable) ? tile_template.walkable : true,
            metadata: metadata
          )
        else
          metadata = add_live_tile_features(zone.name, x, y, {})
          tile = missing_tile(x, y)
          tile.metadata = tile.metadata.merge(metadata)
          row << tile
        end
      end
      tiles << row unless row.empty?
    end

    tiles
  end

  # Add DB-backed NPC/building data to tile metadata.
  # Defeated NPCs are hidden.
  def add_live_tile_features(zone_name, x, y, metadata)
    # Check for TileNpc in database
    npc = TileNpc.at_tile(zone_name, x, y)

    if npc
      # Database record exists - show if alive
      if npc.alive?
        metadata["npc"] = npc.display_name
        metadata["npc_level"] = npc.level
      else
        metadata.delete("npc")
        metadata.delete("npc_level")
      end
    end

    # Check for TileBuilding in database
    building = TileBuilding.active.at_tile(zone_name, x, y)

    if building
      metadata["building"] = building.display_name
      metadata["building_type"] = building.building_type
      metadata["building_icon"] = building.display_icon
    end

    metadata
  end

  def available_actions
    actions = []

    return actions if @active_movement

    # Location-specific actions
    if @position.zone.city? && @position.zone.metadata&.dig("exit_to").present?
      actions << {type: :exit, label: "Выйти из города"}
    end

    # Tile NPC actions
    tile_npc = tile_npc_at_current_tile
    if tile_npc.present?
      actions << {
        type: :tile_npc,
        npc: tile_npc,
        offer: offers_by_action("attack_npc").first
      }
    end

    # Tile Building actions (enterable structures)
    tile_building = tile_building_at_current_tile
    if tile_building.present?
      actions << {
        type: :tile_building,
        building: tile_building,
        offer: offers_by_action("enter_building").first
      }
    end

    actions
  end

  def tile_npc_at_current_tile
    return @tile_npc if defined?(@tile_npc) && @tile_npc
    return @tile_state.npc_info if @tile_state

    # Get tile NPC info at current position (for display)
    service = Game::World::TileNpcService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )
    service.npc_info
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

  def players_at_current_tile
    CharacterPosition
      .includes(:character)
      .where(zone: @position.zone, x: @position.x, y: @position.y)
      .where.not(character_id: current_character.id)
      .where(state: :active)
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

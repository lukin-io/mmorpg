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
    consume_world_action_result
    incremental_response = @map_buffer && incremental_map_request?
    incremental_response ? record_current_session_activity : prepare_presence_context

    # Native reads/entry redirects render a complete page; timed map refreshes
    # return one coherent set of bounded Turbo fragments.
    respond_to do |format|
      format.html do
        if city_zone?
          render "world/city_view"
        else
          render "world/show"
        end
      end
      format.turbo_stream do
        if incremental_response
          render_world_streams
          next
        end

        # For Turbo Stream requests (e.g., after enter_building redirect),
        # render full HTML page to avoid "Content missing"
        # Use formats: [:html] to find the .html.erb template
        if city_zone?
          render "world/city_view", formats: [:html], layout: "game", content_type: "text/html"
        else
          render "world/show", formats: [:html], layout: "game", content_type: "text/html"
        end
      end
    end
  end

  # GET /world/players
  # Refresh the compact location-scoped presence list without replacing the
  # world or city surface.
  def players
    prepare_presence_context(sort: params[:sort])

    render partial: "shared/nl_players_list", layout: false
  end

  def move
    result = Game::Movement::AcceptMove.new(
      character: current_character,
      action_key: params[:action_key],
      target_x: params[:target_x],
      target_y: params[:target_y],
      direction: params[:direction]
    ).call
    return respond_with_world_interruption(result.interruption) if result.interruption&.interrupted?

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
        result.success ? action_offer.complete! : action_offer.fail!(result.message)
      end
    end

    return respond_with_world_interruption(interruption) if interruption.interrupted?

    respond_to do |format|
      if result.success
        destination_path = if result.location_key.present?
          world_location_path(result.location_key)
        else
          world_path
        end

        # Always redirect after entering a building. A city changes the
        # persisted zone; an open-world location keeps the persisted cell and
        # opens its allowlisted interior surface.
        format.html { redirect_to destination_path, notice: result.message }
        format.turbo_stream do
          # Redirect via Turbo - triggers full page navigation
          flash[:notice] = result.message
          redirect_to destination_path, status: :see_other
        end
      else
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
    ActiveRecord::Base.transaction do
      action_offer = accept_world_action!(world_action_type, target: tile)
      result = Game::World::PerformLocalAction.new(
        character: current_character,
        tile:,
        local_action_type:,
        action_offer:
      ).call

      action_offer.fail!(result.message) unless result.success
    end

    return respond_with_world_action_error(result.message) unless result.success

    return respond_with_world_interruption(result.interruption) if result.interruption&.interrupted?

    flash[:world_action_result_offer_id] = result.action_offer.id
    respond_to do |format|
      format.html { redirect_to world_path }
      format.turbo_stream { redirect_to world_path, status: :see_other }
    end
  rescue Game::World::AcceptAction::ActionViolationError,
    Game::World::StartNpcFight::FightViolationError => e
    respond_with_world_action_error(e.message)
  end

  private

  # Flash is a delivery hint, not result authority: a late cookie response may
  # replay it. World reads already hold the character lock; the offer lock makes
  # the persisted result consumable once even across concurrent page requests.
  def consume_world_action_result
    offer_id = flash[:world_action_result_offer_id]
    flash.delete(:world_action_result_offer_id)
    return unless offer_id.is_a?(Integer) && offer_id.positive? && @position.zone.outdoor?

    offer = WorldActionOffer.at_tile(@position.zone, @position.x, @position.y)
      .where(character: current_character, action_type: WorldActionOffer::TIMED_LOCAL_ACTION_TYPES, status: %i[accepted completed])
      .find_by(id: offer_id)
    @world_action_result = offer&.consume_local_action_result!
  end

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
  end

  def prepare_overworld_view
    @movement_state = Game::Movement::MapState.new(character: current_character).call
    @position = @movement_state.position.reload
    @zone = @position.zone
    @active_movement = @movement_state.active_command
    @active_world_action = @movement_state.active_world_action
    @movement_destinations = @movement_state.destinations
    @movement_remaining_seconds = @active_movement&.remaining_seconds || 0
    @movement_cooldown = @movement_destinations.first&.travel_seconds ||
      @active_movement&.travel_seconds ||
      Game::Movement::TravelTime.seconds(wanderer_level: current_character.passive_skill_level(:wanderer))

    @tile_state = @active_movement ? nil : Game::World::TileStateResolver.new(
      character: current_character,
      position: @position
    ).call
    @world_action_offers = (@active_movement || @active_world_action) ? [] : Game::World::ActionOfferBuilder.new(
      character: current_character,
      position: @position,
      tile_state: @tile_state
    ).call

    @tile = current_tile
    @map_buffer = Game::World::MapBuffer.new(
      position: @position,
      columns: params[:map_columns], rows: params[:map_rows],
      token: (params[:map_buffer] if request.format.turbo_stream?)
    ).call
    @nearby_tiles = @map_buffer.rows
    @tile_building = tile_building_at_current_tile
    @available_actions = available_actions
  end

  def ensure_character_position!
    return if current_character.position.present?

    # The captured Forpost Central Square is the only MVP spawn node.
    starter_node = Game::World::CityCatalog.node(Game::World::CityCatalog::STARTER_NODE_KEY)
    starter_zone = Zone.find_by(name: starter_node.fetch("zone_name"), location_type: "city")
    unless starter_zone
      return render "world/no_zones", status: :service_unavailable
    end

    spawn = starter_zone.spawn_points.default_entries.first
    unless spawn
      return render "world/no_zones", status: :service_unavailable
    end

    Game::Movement::RespawnService.new(
      character: current_character,
      spawn_scope: starter_zone.spawn_points.where(id: spawn.id)
    ).ensure_position!
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

  def available_actions
    actions = []

    return actions if @active_movement || @active_world_action

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

  def incremental_map_request?
    request.format.turbo_stream? && params[:map_buffer].present?
  end

  def render_map_update
    current_character.with_lock do
      prepare_overworld_view
      render_world_streams
    end
  end

  def render_world_streams(error: nil)
    streams = [
      world_stream("game-map", partial: "world/map", locals: {
        position: @position, nearby_tiles: @nearby_tiles, zone: @zone,
        movement_destinations: @movement_destinations,
        active_movement: @active_movement,
        movement_remaining_seconds: @movement_remaining_seconds
      }),
      world_stream("location-info", partial: "world/location_info", locals: {
        position: @position, location_label: Game::World::Presence.new(character: current_character, position: @position).label
      }),
      world_stream("available-actions", partial: "world/actions", locals: {
        available_actions: @available_actions, position: @position
      })
    ]
    if @world_action_result.present?
      streams << world_stream("world-action-result", partial: "world/action_result",
        locals: {message: @world_action_result})
    end
    if error
      streams << world_stream("flash", partial: "shared/flash",
        locals: {type: :alert, message: error})
    end
    render turbo_stream: streams, status: error ? :unprocessable_content : :ok
  end

  def world_stream(target, partial:, locals:)
    helpers.turbo_stream_action_tag(:update, target:,
      template: render_to_string(partial:, locals:, formats: [:html]),
      "data-world-map-revision": @map_buffer.revision)
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
    offer = Game::World::AcceptAction.new(
      character: current_character,
      action_key: params[:action_key],
      action_type: action_type,
      target: target,
      position: @position
    ).call
    @position = current_character.position.reload
    offer
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
    return render_error(message) if city_zone?

    current_character.with_lock do
      prepare_overworld_view
      render_world_streams(error: message)
    end
  end
end

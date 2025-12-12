# frozen_string_literal: true

require "ostruct"

# WorldController handles the main game world view, movement between tiles,
# and location-based interactions (entering/exiting buildings, gathering, etc.)
#
# The player sees either:
# - A location view (city, building interior) with NPCs and actions
# - An overworld map grid for movement between tiles
#
# Usage:
#   GET /world              - Show current location
#   POST /world/move        - Move to adjacent tile
#   POST /world/enter       - Enter a building/dungeon
#   POST /world/exit        - Exit to overworld
#   POST /world/gather      - Gather resources at current tile
#   POST /world/interact    - Interact with NPC/object
class WorldController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :ensure_character_position!
  before_action :set_position

  def show
    @zone = @position.zone
    @tile = current_tile
    @nearby_tiles = nearby_tiles_with_features
    @available_actions = available_actions
    @npcs_here = npcs_at_current_tile
    @gathering_nodes = gathering_nodes_at_current_tile
    @tile_resource = tile_resource_at_current_tile
    @tile_npc = tile_npc_at_current_tile
    @players_here = players_at_current_tile
  end

  def move
    direction = params[:direction]&.to_sym

    Game::Movement::TurnProcessor.new(
      character: current_character,
      direction: direction
    ).call

    @position.reload
    respond_to do |format|
      format.turbo_stream { render_map_update }
      format.html { redirect_to world_path, notice: "Moved #{direction}." }
    end
  rescue Game::Movement::TurnProcessor::MovementViolationError => e
    respond_to do |format|
      format.turbo_stream { render_error(e.message) }
      format.html { redirect_to world_path, alert: e.message }
    end
  end

  def enter
    location_key = params[:location_key]

    # Find the zone/building to enter (search by name, case-insensitive)
    target_zone = Zone.find_by("LOWER(name) = ?", location_key.to_s.downcase)

    if target_zone.nil?
      return redirect_to world_path, alert: "Location not found."
    end

    # Find spawn point in target zone
    spawn_point = target_zone.spawn_points.default_entries.first ||
      target_zone.spawn_points.first

    if spawn_point.nil?
      return redirect_to world_path, alert: "No entry point available."
    end

    # Move character to new zone
    @position.update!(
      zone: target_zone,
      x: spawn_point.x,
      y: spawn_point.y,
      last_action_at: Time.current
    )

    redirect_to world_path, notice: "Entered #{target_zone.name}."
  end

  def exit_location
    # Find the parent/outdoor zone
    current_zone = @position.zone
    exit_zone = Zone.find_by(name: current_zone.metadata&.dig("exit_to")) ||
      Zone.find_by(biome: "plains") ||
      Zone.find_by(biome: "forest")

    if exit_zone.nil?
      return redirect_to world_path, alert: "No exit available."
    end

    spawn_point = exit_zone.spawn_points.default_entries.first ||
      exit_zone.spawn_points.first

    @position.update!(
      zone: exit_zone,
      x: spawn_point.x,
      y: spawn_point.y,
      last_action_at: Time.current
    )

    redirect_to world_path, notice: "Exited to #{exit_zone.name}."
  end

  def gather
    node = GatheringNode.find(params[:node_id])

    unless node.zone_id == @position.zone_id
      return redirect_to world_path, alert: "Node is not in your zone."
    end

    unless node.available?
      return redirect_to world_path, alert: "This resource is not available yet."
    end

    # Mark as harvested and award resources
    node.mark_harvest!
    redirect_to world_path, notice: "Gathered #{node.resource_key.titleize}!"
  rescue ActiveRecord::RecordNotFound
    redirect_to world_path, alert: "Resource not found."
  end

  # POST /world/gather_resource
  # Gather a resource from the current tile
  def gather_resource
    service = Game::World::TileGatheringService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )

    result = service.gather!

    respond_to do |format|
      if result.success
        format.html { redirect_to world_path, notice: result.message }
        format.turbo_stream { render_gather_update(result.message) }
        format.json { render json: {success: true, item: result.item_name, quantity: result.quantity, message: result.message} }
      else
        format.html { redirect_to world_path, alert: result.message }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: {type: "alert", message: result.message})
        end
        format.json { render json: {success: false, message: result.message, respawn_in: result.respawn_in}, status: :unprocessable_entity }
      end
    end
  end

  def interact
    npc_id = params[:npc_id] || params[:npc_key]
    npc_template = NpcTemplate.find_by(id: npc_id) || NpcTemplate.find_by(npc_key: npc_id)

    unless npc_template
      return respond_to do |format|
        format.html { redirect_to world_path, alert: "NPC not found." }
        format.json { render json: {error: "NPC not found"}, status: :not_found }
      end
    end

    service = Game::Npc::DialogueService.new(character: current_character, npc_template: npc_template)
    result = service.start_dialogue!

    respond_to do |format|
      if result.success
        format.html { render "world/dialogue", locals: {result: result, npc: npc_template} }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "game-main",
            partial: "world/dialogue",
            locals: {result: result, npc: npc_template}
          )
        end
        format.json { render json: result.to_h }
      else
        format.html { redirect_to world_path, alert: result.message }
        format.json { render json: {error: result.message}, status: :unprocessable_entity }
      end
    end
  end

  # POST /world/dialogue_action
  def dialogue_action
    npc_id = params[:npc_id]
    action_key = params[:action_key]
    action_params = params[:action_params]&.to_unsafe_h || {}

    npc_template = NpcTemplate.find_by(id: npc_id)
    unless npc_template
      return render json: {error: "NPC not found"}, status: :not_found
    end

    service = Game::Npc::DialogueService.new(character: current_character, npc_template: npc_template)
    result = service.process_choice!(action_key, action_params.symbolize_keys)

    respond_to do |format|
      format.turbo_stream do
        if result.success
          case result.dialogue_type
          when :quest_accepted, :quest_completed
            render turbo_stream: [
              turbo_stream.replace("dialogue-content", partial: "world/dialogue_result", locals: {result: result}),
              turbo_stream.replace("flash", partial: "shared/flash", locals: {notice: result.message})
            ]
          when :purchase_complete, :sale_complete, :skill_learned, :rested
            render turbo_stream: [
              turbo_stream.replace("dialogue-content", partial: "world/dialogue_result", locals: {result: result}),
              turbo_stream.replace("player-gold", partial: "shared/player_gold", locals: {gold: current_character.reload.gold})
            ]
          else
            render turbo_stream: turbo_stream.replace("dialogue-content", partial: "world/dialogue_result", locals: {result: result})
          end
        else
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: {alert: result.message})
        end
      end
      format.json { render json: result.to_h }
    end
  end

  private

  def ensure_character_position!
    return if current_character.position.present?

    # Create initial position in starter zone (city)
    starter_zone = Zone.find_by(biome: "city") || Zone.first
    return redirect_to root_path, alert: "No zones available." unless starter_zone

    spawn = starter_zone.spawn_points.default_entries.first ||
      starter_zone.spawn_points.first

    current_character.create_position!(
      zone: starter_zone,
      x: spawn&.x || 5,
      y: spawn&.y || 5,
      state: :active,
      last_turn_number: 0
    )
  end

  def set_position
    @position = current_character.position
  end

  def current_tile
    MapTileTemplate.find_by(
      zone: @position.zone,
      x: @position.x,
      y: @position.y
    ) || default_tile
  end

  def default_tile
    OpenStruct.new(
      terrain_type: @position.zone.biome,
      walkable: true,
      metadata: {}
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
        tile = db_tiles[[x, y]] || OpenStruct.new(
          x: x,
          y: y,
          terrain_type: zone.biome,
          walkable: true,
          passable: true,
          metadata: {}
        )
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

        # Get tile template or generate procedural terrain
        tile_template = MapTileTemplate.find_by(zone: zone, x: x, y: y)

        if tile_template
          # Use tile template but override with actual resource/npc data
          metadata = tile_template.respond_to?(:metadata) ? (tile_template.metadata || {}).dup : {}
          metadata = add_live_tile_features(zone.name, x, y, metadata)

          row << OpenStruct.new(
            x: x,
            y: y,
            terrain_type: tile_template.respond_to?(:terrain_type) ? tile_template.terrain_type : zone.biome,
            walkable: tile_template.respond_to?(:walkable) ? tile_template.walkable : true,
            metadata: metadata
          )
        else
          # Generate procedural terrain based on position
          terrain = procedural_terrain(zone, x, y)
          # Start with empty metadata and add live features
          metadata = add_live_tile_features(zone.name, x, y, {})

          row << OpenStruct.new(
            x: x,
            y: y,
            terrain_type: terrain,
            walkable: terrain != "mountain" && terrain != "river",
            metadata: metadata
          )
        end
      end
      tiles << row unless row.empty?
    end

    tiles
  end

  # Add resource/npc data to tile metadata
  # Priority: 1) Database records (TileResource/TileNpc)
  #           2) Procedural features as fallback
  # Depleted resources (quantity = 0) are hidden
  def add_live_tile_features(zone_name, x, y, metadata)
    # Check for TileResource in database
    resource = TileResource.at_tile(zone_name, x, y)

    if resource
      # Database record exists - show if available, hide if depleted
      if resource.available?
        metadata["resource"] = resource.display_name
        metadata["resource_type"] = resource.resource_type
        metadata["resource_quantity"] = resource.quantity
      else
        # Resource is depleted, don't show it
        metadata.delete("resource")
        metadata.delete("resource_type")
        metadata.delete("resource_quantity")
      end
    else
      # No database record - use procedural features as visual hint
      # Resource will be created when player attempts to gather
      procedural = procedural_features(@position.zone, x, y)
      if procedural["resource"]
        metadata["resource"] = procedural["resource"]
        metadata["resource_type"] = procedural["resource_type"]
      end
    end

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
    else
      # No database record - use procedural features as visual hint
      procedural ||= procedural_features(@position.zone, x, y)
      if procedural["npc"]
        metadata["npc"] = procedural["npc"]
      end
    end

    metadata
  end

  def procedural_terrain(zone, x, y)
    # Use deterministic pseudo-random based on coordinates
    seed = (zone.id * 1000) + (x * 100) + y
    rng = Random.new(seed)

    case zone.biome
    when "city"
      "city"
    when "plains"
      # Plains with occasional features
      roll = rng.rand(100)
      if roll < 5
        "river"
      elsif roll < 15
        "forest"
      else
        "plains"
      end
    when "forest"
      roll = rng.rand(100)
      if roll < 10
        "river"
      elsif roll < 20
        "plains"
      else
        "forest"
      end
    else
      zone.biome
    end
  end

  def procedural_features(zone, x, y)
    seed = (zone.id * 1000) + (x * 100) + y
    rng = Random.new(seed + 42)
    features = {}

    # Don't add features in cities
    return features if zone.biome == "city"

    roll = rng.rand(100)

    if roll < 8 && zone.biome != "city"
      # NPC/Monster
      npcs = ["Goblin Scout", "Wild Boar", "Forest Wolf", "Bandit", "Giant Spider"]
      features["npc"] = npcs[rng.rand(npcs.size)]
    elsif roll < 20
      # Resource node
      resources = case zone.biome
      when "forest"
        [
          {name: "Moonleaf Herb", type: "herb"},
          {name: "Oak Wood", type: "wood"},
          {name: "Wild Berries", type: "herb"}
        ]
      when "plains"
        [
          {name: "Iron Ore", type: "ore"},
          {name: "Healing Herb", type: "herb"},
          {name: "Flax Plant", type: "herb"}
        ]
      when "mountain"
        [
          {name: "Gold Vein", type: "ore"},
          {name: "Crystal Formation", type: "ore"},
          {name: "Mountain Herb", type: "herb"}
        ]
      else
        [{name: "Wild Plant", type: "herb"}]
      end

      resource = resources[rng.rand(resources.size)]
      features["resource"] = resource[:name]
      features["resource_type"] = resource[:type]
    end

    features
  end

  def available_actions
    actions = []

    # Movement actions (if cooldown allows)
    if @position.ready_for_action?(cooldown_seconds: movement_cooldown)
      actions << {type: :move, directions: available_directions}
    end

    # Location-specific actions
    if @position.zone.biome == "city"
      actions << {type: :exit, label: "Exit City"}
    end

    # Gathering actions (profession-based nodes)
    if gathering_nodes_at_current_tile.any?
      actions << {type: :gather, nodes: gathering_nodes_at_current_tile}
    end

    # Tile resource actions (biome-based, no profession required)
    tile_resource = tile_resource_at_current_tile
    if tile_resource.present?
      actions << {type: :tile_resource, resource: tile_resource}
    end

    # Tile NPC actions (biome-based random spawns)
    tile_npc = tile_npc_at_current_tile
    if tile_npc.present?
      actions << {type: :tile_npc, npc: tile_npc}
    end

    actions
  end

  def available_directions
    zone = @position.zone
    directions = []

    # Check each cardinal direction
    directions << :north if @position.y > 0
    directions << :south if @position.y < zone.height - 1
    directions << :west if @position.x > 0
    directions << :east if @position.x < zone.width - 1

    # Check each diagonal direction
    directions << :northeast if @position.y > 0 && @position.x < zone.width - 1
    directions << :southeast if @position.y < zone.height - 1 && @position.x < zone.width - 1
    directions << :southwest if @position.y < zone.height - 1 && @position.x > 0
    directions << :northwest if @position.y > 0 && @position.x > 0

    directions
  end

  def npcs_at_current_tile
    zone = @position.zone
    return [] unless zone

    # Get NPCs that can spawn in this zone
    zone_npcs = NpcTemplate.in_zone(zone.name)

    # Filter by position if NPC has spawn area restrictions
    zone_npcs.select do |npc|
      npc.can_spawn_at?(zone: zone, x: @position.x, y: @position.y)
    end
  end

  def hostile_npcs_at_tile
    npcs_at_current_tile.select { |npc| npc.role == "hostile" }
  end

  def friendly_npcs_at_tile
    npcs_at_current_tile.reject { |npc| npc.role == "hostile" }
  end

  def gathering_nodes_at_current_tile
    # Gathering nodes are zone-wide, shown based on profession requirements
    GatheringNode.where(zone: @position.zone).available.limit(3)
  end

  def tile_resource_at_current_tile
    # Get tile resource info at current position (for display)
    service = Game::World::TileGatheringService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )
    service.resource_info
  end

  def tile_npc_at_current_tile
    # Get tile NPC info at current position (for display)
    service = Game::World::TileNpcService.new(
      character: current_character,
      zone: @position.zone.name,
      x: @position.x,
      y: @position.y
    )
    service.npc_info
  end

  def players_at_current_tile
    CharacterPosition
      .includes(:character)
      .where(zone: @position.zone, x: @position.x, y: @position.y)
      .where.not(character_id: current_character.id)
      .where(state: :active)
      .limit(10)
  end

  def movement_cooldown
    # Movement cooldown formula:
    # 1. Base: 10 seconds
    # 2. Wanderer skill: reduces by 0-70% based on skill level
    # 3. Terrain modifier: multiplies based on terrain type
    # 4. Mount speed: divides by mount travel multiplier
    base = Game::Skills::PassiveSkillCalculator::BASE_MOVEMENT_COOLDOWN

    # Apply Wanderer skill
    wanderer_adjusted = current_character.passive_skill_calculator.apply_movement_cooldown(base)

    # Apply terrain modifier
    terrain_modifier = begin
      Game::Movement::TerrainModifier.new(zone: @position.zone).speed_multiplier(tile_metadata: current_tile_metadata)
    rescue
      1.0
    end

    # Apply mount speed
    mount_multiplier = begin
      active_mount = current_character.user&.mounts&.find_by(summon_state: :summoned)
      active_mount ? active_mount.travel_multiplier : 1.0
    rescue
      1.0
    end

    ((wanderer_adjusted * terrain_modifier) / mount_multiplier).round.to_i
  end

  def current_tile_metadata
    tile = MapTileTemplate.find_by(zone: @position.zone, x: @position.x, y: @position.y)
    tile&.metadata || {}
  end

  def render_map_update
    # Set instance variables that partials expect
    @movement_cooldown = movement_cooldown
    @tile = current_tile
    @zone = @position.zone
    @nearby_tiles = nearby_tiles_with_features
    @available_actions = available_actions

    render turbo_stream: [
      turbo_stream.update("game-map", partial: "world/map", locals: {
        position: @position,
        nearby_tiles: @nearby_tiles,
        zone: @zone,
        tile_data: {}
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

  # Render update after gathering a resource
  # Updates map (to show resource state), location info, actions, and flash message
  def render_gather_update(message)
    # Set instance variables that partials expect
    @movement_cooldown = movement_cooldown
    @tile = current_tile
    @zone = @position.zone
    @nearby_tiles = nearby_tiles_with_features
    @available_actions = available_actions

    render turbo_stream: [
      turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: message}),
      turbo_stream.update("game-map", partial: "world/map", locals: {
        position: @position,
        nearby_tiles: @nearby_tiles,
        zone: @zone,
        tile_data: {}
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
end

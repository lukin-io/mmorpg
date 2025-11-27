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
    @players_here = players_at_current_tile
  end

  def move
    direction = params[:direction]&.to_sym

    result = Game::Movement::TurnProcessor.new(
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

    # Find the zone/building to enter
    target_zone = Zone.find_by(slug: location_key) || Zone.find_by(name: location_key)

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

  def interact
    # Handle NPC interactions, object interactions, etc.
    npc_key = params[:npc_key]

    # TODO: Implement NPC dialogue system
    redirect_to world_path, notice: "Interacted with #{npc_key}."
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
          row << tile_template
        else
          # Generate procedural terrain based on position
          terrain = procedural_terrain(zone, x, y)
          metadata = procedural_features(zone, x, y)

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
      case zone.biome
      when "forest"
        resources = [
          {name: "Moonleaf Herb", type: "herb"},
          {name: "Oak Wood", type: "wood"},
          {name: "Wild Berries", type: "herb"}
        ]
      when "plains"
        resources = [
          {name: "Iron Ore", type: "ore"},
          {name: "Healing Herb", type: "herb"},
          {name: "Flax Plant", type: "herb"}
        ]
      when "mountain"
        resources = [
          {name: "Gold Vein", type: "ore"},
          {name: "Crystal Formation", type: "ore"},
          {name: "Mountain Herb", type: "herb"}
        ]
      else
        resources = [{name: "Wild Plant", type: "herb"}]
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

    # Gathering actions
    if gathering_nodes_at_current_tile.any?
      actions << {type: :gather, nodes: gathering_nodes_at_current_tile}
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

    directions
  end

  def npcs_at_current_tile
    # TODO: Query NPC templates/instances at current position
    []
  end

  def gathering_nodes_at_current_tile
    # Gathering nodes are zone-wide, shown based on profession requirements
    GatheringNode.where(zone: @position.zone).available.limit(3)
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
    # Base cooldown, can be modified by terrain/buffs
    base = 3 # seconds
    terrain_modifier = Game::Movement::TerrainModifier.new(
      zone: @position.zone,
      x: @position.x,
      y: @position.y
    ).cooldown_multiplier rescue 1.0

    (base * terrain_modifier).to_i
  end

  def render_map_update
    render turbo_stream: [
      turbo_stream.replace("game-map", partial: "world/map", locals: {
        position: @position,
        nearby_tiles: nearby_tiles,
        zone: @position.zone
      }),
      turbo_stream.replace("location-info", partial: "world/location_info", locals: {
        position: @position,
        tile: current_tile,
        zone: @position.zone
      }),
      turbo_stream.replace("available-actions", partial: "world/actions", locals: {
        available_actions: available_actions,
        position: @position
      })
    ]
  end

  def render_error(message)
    render turbo_stream: turbo_stream.replace(
      "flash-messages",
      partial: "shared/flash",
      locals: {type: :alert, message: message}
    )
  end
end

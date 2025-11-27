# frozen_string_literal: true

module WorldHelper
  # Get icon for building type
  #
  # @param type [String, Symbol] the building type
  # @return [String] emoji icon for the building
  def building_icon(type)
    icons = {
      shop: "🏪",
      tavern: "🍺",
      blacksmith: "⚒️",
      bank: "🏦",
      arena: "⚔️",
      guild: "🏰",
      temple: "⛪",
      academy: "📚",
      market: "🛒",
      stable: "🐴",
      gate: "🚪",
      house: "🏠",
      fountain: "⛲",
      statue: "🗿",
      tower: "🗼",
      inn: "🏨",
      library: "📖",
      alchemist: "⚗️",
      jeweler: "💎",
      tailor: "🧵",
      bakery: "🥖",
      warehouse: "📦"
    }
    icons[type.to_sym] || "🏛️"
  end

  # Get buildings for a city zone
  #
  # @param zone [Zone] the city zone
  # @return [Array<Hash>] array of building data
  def city_buildings(zone)
    # Try to get buildings from zone metadata or MapTileTemplates
    buildings = zone.metadata&.dig("buildings") || []

    if buildings.empty?
      # Fall back to MapTileTemplates with building metadata
      templates = MapTileTemplate.where(zone: zone).where("metadata->>'building_type' IS NOT NULL")
      buildings = templates.map do |template|
        {
          id: template.id,
          name: template.metadata["building_name"] || template.metadata["building_type"]&.titleize,
          type: template.metadata["building_type"],
          key: template.metadata["building_key"] || template.metadata["building_type"],
          description: template.metadata["building_description"],
          grid_x: template.x,
          grid_y: template.y,
          npcs: template.metadata["npcs"] || []
        }
      end
    end

    # If still empty, generate default city buildings
    if buildings.empty?
      buildings = default_city_buildings
    end

    buildings.map { |b| b.is_a?(Hash) ? b.symbolize_keys : b }
  end

  # Default buildings for a generic city
  #
  # @return [Array<Hash>] default building data
  def default_city_buildings
    [
      {id: 1, name: "General Store", type: "shop", key: "general_store", grid_x: 1, grid_y: 1,
       description: "Buy supplies and sell your loot here.", npcs: [{key: "merchant", name: "Merchant Elara"}]},
      {id: 2, name: "The Golden Tankard", type: "tavern", key: "tavern", grid_x: 3, grid_y: 1,
       description: "Rest, eat, and hear the latest rumors.", npcs: [{key: "innkeeper", name: "Innkeeper Bram"}]},
      {id: 3, name: "Ironforge Smithy", type: "blacksmith", key: "blacksmith", grid_x: 5, grid_y: 1,
       description: "Weapons and armor crafted with skill.", npcs: [{key: "smith", name: "Smith Gorn"}]},
      {id: 4, name: "City Bank", type: "bank", key: "bank", grid_x: 1, grid_y: 3,
       description: "Store your gold and valuables safely.", npcs: [{key: "banker", name: "Banker Wells"}]},
      {id: 5, name: "Arena", type: "arena", key: "arena", grid_x: 5, grid_y: 3,
       description: "Test your strength against other warriors!", npcs: []},
      {id: 6, name: "Guild Hall", type: "guild", key: "guild_hall", grid_x: 3, grid_y: 5,
       description: "The center of guild activities.", npcs: [{key: "guild_master", name: "Guild Master Aldric"}]},
      {id: 7, name: "Temple of Light", type: "temple", key: "temple", grid_x: 1, grid_y: 5,
       description: "Heal your wounds and seek divine guidance.", npcs: [{key: "priest", name: "Priestess Luna"}]},
      {id: 8, name: "City Gate", type: "gate", key: "city_gate", grid_x: 5, grid_y: 5,
       description: "The main entrance to the city.", npcs: [{key: "guard", name: "Gate Guard"}]}
    ]
  end

  # Get terrain icon for map tile
  #
  # @param terrain_type [String] the terrain type
  # @return [String] emoji icon
  def terrain_icon(terrain_type)
    icons = {
      "plains" => "🌾",
      "forest" => "🌲",
      "mountain" => "⛰️",
      "river" => "🌊",
      "lake" => "💧",
      "desert" => "🏜️",
      "snow" => "❄️",
      "swamp" => "🌿",
      "city" => "🏙️",
      "dungeon" => "🕳️",
      "cave" => "🕳️",
      "road" => "🛤️"
    }
    icons[terrain_type.to_s] || "🗺️"
  end

  # Get NPC icon
  #
  # @param npc_type [String] the NPC type or name
  # @return [String] emoji icon
  def npc_icon(npc_type)
    type = npc_type.to_s.downcase
    icons = {
      "wolf" => "🐺",
      "boar" => "🐗",
      "spider" => "🕷️",
      "goblin" => "👺",
      "bandit" => "🥷",
      "skeleton" => "💀",
      "zombie" => "🧟",
      "dragon" => "🐉",
      "merchant" => "🧑‍💼",
      "guard" => "💂",
      "villager" => "🧑‍🌾",
      "mage" => "🧙",
      "knight" => "🤺",
      "priest" => "🧑‍⚕️"
    }

    icons.each do |key, icon|
      return icon if type.include?(key)
    end

    "👤"
  end

  # Get resource icon
  #
  # @param resource_type [String] the resource type
  # @return [String] emoji icon
  def resource_icon(resource_type)
    icons = {
      "herb" => "🌿",
      "ore" => "⛏️",
      "wood" => "🪵",
      "fish" => "🐟",
      "gem" => "💎",
      "leather" => "🦊",
      "cloth" => "🧵"
    }
    icons[resource_type.to_s] || "📦"
  end

  # Check if position is in a city/town zone
  #
  # @param position [CharacterPosition] the position
  # @return [Boolean] true if in a city
  def in_city?(position)
    zone = position.zone
    zone.biome == "city" || zone.metadata&.dig("zone_type") == "city"
  end

  # Format coordinates for display
  #
  # @param x [Integer] x coordinate
  # @param y [Integer] y coordinate
  # @return [String] formatted coordinates
  def format_coordinates(x, y)
    "[#{x}, #{y}]"
  end

  # Get directional arrow for movement
  #
  # @param direction [Symbol] the direction
  # @return [String] arrow character
  def direction_arrow(direction)
    arrows = {
      north: "▲",
      south: "▼",
      east: "▶",
      west: "◀",
      northeast: "↗",
      northwest: "↖",
      southeast: "↘",
      southwest: "↙"
    }
    arrows[direction.to_sym] || "•"
  end
end

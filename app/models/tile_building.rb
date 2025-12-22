# frozen_string_literal: true

# TileBuilding tracks enterable structures at specific map tiles.
# Buildings allow players to transition between zones (e.g., entering a castle,
# dungeon, inn, or portal).
#
# Usage:
#   TileBuilding.at_tile(zone_name, x, y) # Find building at tile
#   TileBuilding.active                    # Buildings that can be entered
#   building.can_enter?(character)         # Check if character meets requirements
#   building.enter!(character)             # Move character to destination zone
#
class TileBuilding < ApplicationRecord
  BUILDING_TYPES = %w[city castle fort inn shop dungeon_entrance portal guild_hall tavern temple].freeze

  BUILDING_ICONS = {
    "city" => "🏙️",
    "castle" => "🏰",
    "fort" => "🏯",
    "inn" => "🏨",
    "shop" => "🏪",
    "dungeon_entrance" => "⚔️",
    "portal" => "🌀",
    "guild_hall" => "🏛️",
    "tavern" => "🍺",
    "temple" => "⛪"
  }.freeze

  belongs_to :destination_zone, class_name: "Zone", optional: true

  validates :zone, :x, :y, :building_key, :name, presence: true
  validates :building_type, inclusion: {in: BUILDING_TYPES}
  validates :building_key, uniqueness: true
  validates :required_level, numericality: {greater_than_or_equal_to: 1}
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(building_type: type) }

  # Find building at specific tile coordinates (returns single record or nil)
  #
  # @param zone [String] zone name
  # @param x [Integer] x coordinate
  # @param y [Integer] y coordinate
  # @return [TileBuilding, nil]
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end

  # Get display name for the building
  #
  # @return [String]
  def display_name
    name.presence || building_key.titleize
  end

  # Get the icon for this building (uses custom icon or default for type)
  #
  # @return [String] emoji icon
  def display_icon
    icon.presence || BUILDING_ICONS[building_type] || "🏰"
  end

  # Check if building is accessible (active and destination exists)
  #
  # @return [Boolean]
  def accessible?
    active? && destination_zone.present?
  end

  # Check if a character can enter this building
  #
  # @param character [Character] the character trying to enter
  # @return [Boolean]
  def can_enter?(character)
    return false unless accessible?
    return false if character.level < required_level
    return false if faction_key.present? && character_faction(character) != faction_key

    # Check additional requirements from metadata
    check_metadata_requirements(character)
  end

  # Get the reason why a character cannot enter
  #
  # @param character [Character] the character trying to enter
  # @return [String, nil] error message or nil if can enter
  def entry_blocked_reason(character)
    return "This building is currently inaccessible." unless accessible?
    return "You must be level #{required_level} to enter." if character.level < required_level

    if faction_key.present? && character_faction(character) != faction_key
      return "Only members of the #{faction_key.titleize} faction may enter."
    end

    unless check_metadata_requirements(character)
      return metadata["requirement_message"] || "You do not meet the requirements to enter."
    end

    nil
  end

  # Move a character into this building's destination zone
  #
  # @param character [Character] the character to move
  # @return [Boolean] true if successful
  def enter!(character)
    return false unless can_enter?(character)

    position = character.position
    return false unless position

    # Determine spawn coordinates in destination
    spawn_x = destination_x || default_spawn_x
    spawn_y = destination_y || default_spawn_y

    position.update!(
      zone: destination_zone,
      x: spawn_x,
      y: spawn_y,
      last_action_at: Time.current
    )

    true
  end

  # Get building info hash for display
  #
  # @return [Hash]
  def to_info_hash
    {
      id: id,
      name: display_name,
      building_type: building_type,
      icon: display_icon,
      destination: destination_zone&.name,
      required_level: required_level,
      faction_key: faction_key,
      active: active?,
      description: metadata["description"]
    }
  end

  private

  def character_faction(character)
    # Get character's faction from clan or other source
    character.respond_to?(:faction_key) ? character.faction_key : nil
  end

  def check_metadata_requirements(character)
    # Check quest requirements
    if metadata["required_quest"].present?
      return false unless character_has_completed_quest?(character, metadata["required_quest"])
    end

    # Check item requirements
    if metadata["required_item"].present?
      return false unless character_has_item?(character, metadata["required_item"])
    end

    true
  end

  def character_has_completed_quest?(character, quest_key)
    return false unless character.respond_to?(:quest_assignments)

    character.quest_assignments.joins(:quest)
      .where(quests: {key: quest_key}, status: "completed")
      .exists?
  end

  def character_has_item?(character, item_key)
    return false unless character.respond_to?(:inventory)

    character.inventory&.inventory_items&.joins(:item_template)
      &.where(item_templates: {key: item_key})
      &.exists? || false
  end

  def default_spawn_x
    spawn_point = destination_zone&.spawn_points&.default_entries&.first ||
      destination_zone&.spawn_points&.first

    spawn_point&.x || (destination_zone&.width || 10) / 2
  end

  def default_spawn_y
    spawn_point = destination_zone&.spawn_points&.default_entries&.first ||
      destination_zone&.spawn_points&.first

    spawn_point&.y || (destination_zone&.height || 10) / 2
  end
end

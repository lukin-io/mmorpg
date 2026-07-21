# frozen_string_literal: true

# TileBuilding tracks a captured city entrance at a specific outdoor cell.
#
# Usage:
#   TileBuilding.at_tile(zone_name, x, y) # Find building at tile
#   TileBuilding.active                    # Entrances that can be used
#   building.can_enter?(character)         # Check whether the entrance is usable
#   building.enter!(character)             # Move character to its authored node
#
class TileBuilding < ApplicationRecord
  BUILDING_TYPES = %w[city].freeze

  belongs_to :destination_zone, class_name: "Zone", optional: true

  validates :zone, :x, :y, :building_key, :name, presence: true
  validates :building_type, inclusion: {in: BUILDING_TYPES}
  validates :building_key, uniqueness: true
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }
  scope :active, -> { where(active: true) }

  # Find building at specific tile coordinates (returns single record or nil)
  #
  # @param zone [String] zone name
  # @param x [Integer] x coordinate
  # @param y [Integer] y coordinate
  # @return [TileBuilding, nil]
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end

  # Check if the captured entrance has a complete authored destination.
  #
  # @return [Boolean]
  def accessible?
    active? && destination_zone.present? && destination_coordinates_valid?
  end

  # Check if a character can use this entrance.
  #
  # @param character [Character] the character trying to enter
  # @return [Boolean]
  def can_enter?(character)
    return false unless accessible?
    return false unless character

    character.position.present?
  end

  # Get the reason why a character cannot enter
  #
  # @param character [Character] the character trying to enter
  # @return [String, nil] error message or nil if can enter
  def entry_blocked_reason(character)
    return "Entrance is currently unavailable." unless accessible?
    return "Character is unavailable." unless character&.position

    nil
  end

  # Move a character to this entrance's authored city node.
  #
  # @param character [Character] the character to move
  # @return [Boolean] true if successful
  def enter!(character)
    return false unless can_enter?(character)

    position = character.position
    return false unless position

    position.update!(
      zone: destination_zone,
      x: destination_x,
      y: destination_y,
      last_action_at: Time.current
    )

    true
  end

  private

  def destination_coordinates_valid?
    destination_x&.between?(0, destination_zone.width - 1) &&
      destination_y&.between?(0, destination_zone.height - 1)
  end
end

# frozen_string_literal: true

# MapTileTemplate defines terrain, passability, and metadata for each tile in a zone.
# Tiles can have NPCs, resources, buildings, and special terrain features.
# Note: `zone` is stored as a string (zone name), not a foreign key.
class MapTileTemplate < ApplicationRecord
  validates :zone, presence: true
  validates :x, presence: true
  validates :y, presence: true
  validates :terrain_type, presence: true

  scope :in_zone, ->(zone_or_name) {
    name = zone_or_name.is_a?(Zone) ? zone_or_name.name : zone_or_name
    where(zone: name)
  }
  scope :in_area, ->(x_range, y_range) { where(x: x_range, y: y_range) }
  scope :passable_only, -> { where(passable: true) }

  # Alias for view compatibility
  def walkable
    passable
  end

  def blocked?
    !passable || metadata&.dig("blocked")
  end

  def has_npc?
    metadata&.dig("npc").present?
  end

  def has_resource?
    metadata&.dig("resource").present?
  end

  def has_building?
    metadata&.dig("building").present?
  end

  # Get the biome, falling back to terrain_type
  def biome
    super || terrain_type
  end
end

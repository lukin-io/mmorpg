# frozen_string_literal: true

# MapTileTemplate defines explicit source-backed tile display/passability data.
# Note: `zone` is stored as a string (zone name), not a foreign key.
class MapTileTemplate < ApplicationRecord
  validates :zone, presence: true
  validates :x, presence: true
  validates :y, presence: true
  validates :terrain_type, presence: true
  validates :terrain_type, inclusion: {in: Zone::LOCATION_TYPES}
  validate :zone_must_be_string

  # Custom setter to ensure zone is always stored as a string name
  def zone=(value)
    super(value.is_a?(Zone) ? value.name : value)
  end

  private

  def zone_must_be_string
    if zone.present? && zone.to_s.start_with?("#<Zone:")
      errors.add(:zone, "must be a zone name string, not a Zone object")
    end
  end

  public

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

  def has_building?
    metadata&.dig("building").present?
  end
end

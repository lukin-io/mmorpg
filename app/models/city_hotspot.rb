# frozen_string_literal: true

# CityHotspot represents a source-backed city action such as a district
# transition, building entry, or captured gate.
#
# Usage:
#   CityHotspot.for_zone(zone)           # Get all active hotspots for a zone
#   hotspot.can_interact?(character)     # Check if character meets requirements
#
class CityHotspot < ApplicationRecord
  HOTSPOT_TYPES = %w[building district exit].freeze
  ACTION_TYPES = %w[enter_zone open_feature].freeze

  FEATURE_ROUTES = {
    "arena" => "/arena",
    "shop" => "/shop",
    "market" => "/city/buildings/market",
    "junk_dealer" => "/city/buildings/junk_dealer",
    "numismatics" => "/city/buildings/numismatics",
    "airship_station" => "/city/buildings/airship_station",
    "hospital" => "/city/buildings/hospital"
  }.freeze

  belongs_to :zone
  belongs_to :destination_zone, class_name: "Zone", optional: true

  validates :key, presence: true, uniqueness: {scope: :zone_id}
  validates :name, presence: true
  validates :hotspot_type, presence: true, inclusion: {in: HOTSPOT_TYPES}
  validates :action_type, presence: true, inclusion: {in: ACTION_TYPES}
  validates :position_x, :position_y, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :required_level, numericality: {greater_than_or_equal_to: 1}
  validates :z_index, numericality: {only_integer: true}

  scope :for_zone, ->(zone) { where(zone: zone).where(active: true).order(:z_index) }
  scope :active, -> { where(active: true) }
  # Check if a character can interact with this hotspot
  #
  # @param character [Character] the character trying to interact
  # @return [Boolean]
  def can_interact?(character)
    return false unless active?
    return false unless character
    return false if character.level < required_level

    true
  end

  # Get the reason why interaction is blocked
  #
  # @param character [Character] the character trying to interact
  # @return [String, nil] error message or nil if can interact
  def interaction_blocked_reason(character)
    return "Location is currently unavailable." unless active?
    return "Character is unavailable." unless character
    return "Requires level #{required_level}." if character.level < required_level

    nil
  end

  # Get the navigation URL for this hotspot based on action type
  #
  # @return [String, nil] URL path or nil if no navigation
  def navigate_url
    case action_type
    when "enter_zone"
      nil # Handled by controller to update character position
    when "open_feature"
      FEATURE_ROUTES[action_params.to_h["feature"]]
    end
  end

  def world_action_type
    return "enter_city_building" if action_type == "open_feature"
    return "city_transition" if destination_zone&.city?

    "exit_city"
  end
end

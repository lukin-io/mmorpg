# frozen_string_literal: true

# CityHotspot represents a clickable area in a city zone view.
# City hotspots are source-backed navigation points such as Arena, Shop, or
# a city exit.
#
# Usage:
#   CityHotspot.for_zone(zone)           # Get all active hotspots for a zone
#   hotspot.can_interact?(character)     # Check if character meets requirements
#   hotspot.navigate_url                 # Get the destination URL for the hotspot
#
class CityHotspot < ApplicationRecord
  HOTSPOT_TYPES = %w[building exit].freeze
  ACTION_TYPES = %w[enter_zone open_feature].freeze

  FEATURE_ROUTES = {
    "arena" => "/arena"
  }.freeze

  PENDING_FEATURES = {
    "shop" => "Лавка задокументирована по Neverlands и ожидает реализации."
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
  scope :buildings, -> { where(hotspot_type: "building") }
  scope :exits, -> { where(hotspot_type: "exit") }
  scope :clickable, -> { where.not(action_type: "none") }

  # Check if a character can interact with this hotspot
  #
  # @param character [Character] the character trying to interact
  # @return [Boolean]
  def can_interact?(character)
    return false unless active?
    return false if character.level < required_level

    true
  end

  # Get the reason why interaction is blocked
  #
  # @param character [Character] the character trying to interact
  # @return [String, nil] error message or nil if can interact
  def interaction_blocked_reason(character)
    return "Локация сейчас недоступна." unless active?
    return "Нужен уровень #{required_level}." if character.level < required_level

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
      feature_key = action_params["feature"] || key
      FEATURE_ROUTES[feature_key]
    end
  end

  # Check if this hotspot is clickable
  #
  # @return [Boolean]
  def clickable?
    active?
  end

  # Get display icon based on hotspot type
  #
  # @return [String] emoji icon
  def display_icon
    case hotspot_type
    when "building" then "🏛️"
    when "exit" then "🚪"
    else "📍"
    end
  end

  # Get CSS class for hotspot type
  #
  # @return [String]
  def css_class
    "city-hotspot city-hotspot--#{hotspot_type}"
  end

  # Convert to hash for JSON responses
  #
  # @return [Hash]
  def to_info_hash
    {
      id: id,
      key: key,
      name: name,
      hotspot_type: hotspot_type,
      position_x: position_x,
      position_y: position_y,
      image_normal: image_normal,
      image_hover: image_hover,
      action_type: action_type,
      destination: destination_zone&.name,
      required_level: required_level,
      active: active?,
      clickable: clickable?
    }
  end
end

# frozen_string_literal: true

# Zone represents either an outdoor coordinate region or one persisted city
# node. City navigation is defined by CityHotspot actions, not zone-grid tiles.
class Zone < ApplicationRecord
  LOCATION_TYPES = %w[outdoor city].freeze

  has_many :spawn_points, dependent: :destroy
  has_many :character_positions, dependent: :restrict_with_exception
  has_many :world_action_offers, dependent: :destroy
  has_many :arena_matches, dependent: :nullify
  has_many :city_hotspots, dependent: :restrict_with_error
  has_many :incoming_city_hotspots,
    class_name: "CityHotspot",
    foreign_key: :destination_zone_id,
    inverse_of: :destination_zone,
    dependent: :restrict_with_error
  has_many :destination_tile_buildings,
    class_name: "TileBuilding",
    foreign_key: :destination_zone_id,
    inverse_of: :destination_zone,
    dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :location_type, presence: true, inclusion: {in: LOCATION_TYPES}
  validates :width, :height, numericality: {greater_than: 0}

  def city?
    location_type == "city"
  end

  def outdoor?
    location_type == "outdoor"
  end

  def city_node_key
    metadata.to_h["city_node_key"]
  end

  def display_name
    metadata.to_h["title"].presence || name
  end

  def city_presentation
    value = metadata.to_h["city_presentation"]
    value.respond_to?(:deep_stringify_keys) ? value.deep_stringify_keys : {}
  end
end

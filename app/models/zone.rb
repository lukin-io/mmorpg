# frozen_string_literal: true

# Zone represents either an outdoor coordinate region or one persisted city
# node. City navigation is defined by CityHotspot actions, not zone-grid tiles.
class Zone < ApplicationRecord
  LOCATION_TYPES = %w[outdoor city].freeze

  has_many :spawn_points, dependent: :destroy
  has_many :map_tile_templates, foreign_key: :zone, primary_key: :name, dependent: :restrict_with_error
  has_many :tile_npcs, foreign_key: :zone, primary_key: :name, dependent: :restrict_with_error
  has_many :tile_buildings, foreign_key: :zone, primary_key: :name, dependent: :restrict_with_error
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
  validate :populated_name_is_stable

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

  private

  # Sparse content uses the unique Zone name as its persisted region key.
  # Display changes belong in metadata.title; renaming a populated key would
  # detach that content while character/command zone_id references survive.
  def populated_name_is_stable
    return unless persisted? && will_save_change_to_name?
    return unless [MapTileTemplate, TileNpc, TileBuilding].any? { |type| type.where(zone: name_in_database).exists? }

    errors.add(:name, "identifies populated region content; change the display title instead")
  end
end

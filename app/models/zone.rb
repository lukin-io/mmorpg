# frozen_string_literal: true

# Zone represents a contiguous tile grid with biome metadata and encounter tables.
# Zones gate movement turns, spawn points, and biome-aware encounters.
class Zone < ApplicationRecord
  BIOMES = %w[plains forest mountain river city castle desert tundra swamp].freeze

  has_many :spawn_points, dependent: :destroy
  has_many :character_positions, dependent: :restrict_with_exception
  has_many :gathering_nodes, dependent: :destroy
  has_many :battles, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :biome, presence: true, inclusion: {in: BIOMES}
  validates :width, :height, numericality: {greater_than: 0}
end

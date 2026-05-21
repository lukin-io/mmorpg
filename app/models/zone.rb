# frozen_string_literal: true

# Zone represents a contiguous tile grid for movement, spawn points, and city or
# outdoor location state.
class Zone < ApplicationRecord
  BIOMES = %w[plains forest mountain river city lake].freeze

  has_many :spawn_points, dependent: :destroy
  has_many :character_positions, dependent: :restrict_with_exception
  has_many :world_action_offers, dependent: :destroy
  has_many :arena_matches, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :biome, presence: true, inclusion: {in: BIOMES}
  validates :width, :height, numericality: {greater_than: 0}
end

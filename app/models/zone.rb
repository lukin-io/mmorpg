# frozen_string_literal: true

# Zone represents a contiguous tile grid for movement, spawn points, and city or
# outdoor location state.
class Zone < ApplicationRecord
  LOCATION_TYPES = %w[outdoor city].freeze

  has_many :spawn_points, dependent: :destroy
  has_many :character_positions, dependent: :restrict_with_exception
  has_many :world_action_offers, dependent: :destroy
  has_many :arena_matches, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :location_type, presence: true, inclusion: {in: LOCATION_TYPES}
  validates :width, :height, numericality: {greater_than: 0}

  def city?
    location_type == "city"
  end

  def outdoor?
    location_type == "outdoor"
  end
end

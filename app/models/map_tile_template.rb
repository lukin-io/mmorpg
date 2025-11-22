# frozen_string_literal: true

class MapTileTemplate < ApplicationRecord
  validates :zone, presence: true
  validates :x, presence: true
  validates :y, presence: true
  validates :terrain_type, presence: true
  validates :biome, presence: true
end

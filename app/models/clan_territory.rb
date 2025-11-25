# frozen_string_literal: true

class ClanTerritory < ApplicationRecord
  belongs_to :clan

  validates :territory_key, presence: true, uniqueness: true
  validates :tax_rate_basis_points, numericality: {greater_than_or_equal_to: 0}

  def tax_rate
    tax_rate_basis_points / 10_000.0
  end

  def world_region
    key = world_region_key.presence || territory_key
    Game::World::RegionCatalog.instance.region_for_territory(key)
  end

  def clan_bonuses
    (world_region&.clan_bonuses || {}).merge(benefits || {})
  end

  def fast_travel_node
    fast_travel_node_key || clan_bonuses.dig("fast_travel", "node_key")
  end
end

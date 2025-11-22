# frozen_string_literal: true

class ClanTerritory < ApplicationRecord
  belongs_to :clan

  validates :territory_key, presence: true, uniqueness: true
  validates :tax_rate_basis_points, numericality: {greater_than_or_equal_to: 0}

  def tax_rate
    tax_rate_basis_points / 10_000.0
  end

  def world_region
    Game::World::RegionCatalog.instance.region_for_territory(territory_key)
  end

  def clan_bonuses
    world_region&.clan_bonuses || {}
  end
end

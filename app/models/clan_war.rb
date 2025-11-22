# frozen_string_literal: true

class ClanWar < ApplicationRecord
  enum :status, {
    scheduled: 0,
    active: 1,
    resolved: 2,
    cancelled: 3
  }

  belongs_to :attacker_clan, class_name: "Clan"
  belongs_to :defender_clan, class_name: "Clan"

  validates :territory_key, presence: true
  validates :scheduled_at, presence: true

  def world_region
    Game::World::RegionCatalog.instance.region_for_territory(territory_key)
  end
end

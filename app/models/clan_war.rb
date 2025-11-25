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
  belongs_to :battle, optional: true

  validates :territory_key, presence: true
  validates :scheduled_at, presence: true

  def world_region
    Game::World::RegionCatalog.instance.region_for_territory(territory_key)
  end

  def resolve!(winner_clan:, battle_record: nil, result_metadata: {})
    update!(
      status: :resolved,
      resolved_at: Time.current,
      battle: battle_record || battle,
      result_payload: result_payload.merge(result_metadata)
    )
    Clans::TerritoryManager.new(territory_key: territory_key).assign!(clan: winner_clan)
  end

  def support_objective_keys
    Array(support_objectives)
  end
end

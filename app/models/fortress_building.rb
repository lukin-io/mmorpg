# frozen_string_literal: true

class FortressBuilding < ApplicationRecord
  # Catalog of upgradable fortress structures. Bonuses feed formula layers
  # (attack/defense/hp/travel) for every living clan member while owned.
  CATALOG = {
    "barracks" => {
      "name" => "Казарма",
      "bonuses_per_level" => {"attack" => 2, "hp" => 5}
    },
    "walls" => {
      "name" => "Стены",
      "bonuses_per_level" => {"defense" => 3, "hp" => 8}
    },
    "workshop" => {
      "name" => "Мастерская",
      "bonuses_per_level" => {"accuracy" => 1, "luck" => 1}
    },
    "watchtower" => {
      "name" => "Дозорная башня",
      "bonuses_per_level" => {"travel_reduction_seconds" => 1, "evasion" => 1}
    },
    "treasury" => {
      "name" => "Сокровищница",
      "bonuses_per_level" => {"nv_find_bonus_percent" => 2}
    },
    "laboratory" => {
      "name" => "Лаборатория",
      "bonuses_per_level" => {}
    }
  }.freeze

  MAX_LEVEL = 10

  belongs_to :world_fortress

  validates :building_key, inclusion: {in: CATALOG.keys}
  validates :building_key, uniqueness: {scope: :world_fortress_id}
  validates :level, numericality: {only_integer: true, in: 1..MAX_LEVEL}

  def self.bonus_totals_for_clan(clan)
    return {} if clan.blank?

    totals = Hash.new(0)
    WorldFortress.where(owner_clan_id: clan.id, active: true).includes(:fortress_buildings).find_each do |fort|
      fort.fortress_buildings.each do |building|
        per = CATALOG.dig(building.building_key, "bonuses_per_level") || {}
        per.each do |key, amount|
          totals[key.to_s] += amount.to_i * building.level.to_i
        end
      end
    end
    totals
  end

  def upgrade!
    raise ArgumentError, I18n.t("game.world.fortress_building_max") if level >= MAX_LEVEL

    self.level += 1
    self.bonuses = (CATALOG.dig(building_key, "bonuses_per_level") || {}).transform_values { |v| v.to_i * level }
    save!
  end
end

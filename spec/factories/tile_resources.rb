# frozen_string_literal: true

FactoryBot.define do
  factory :tile_resource do
    sequence(:x) { |n| n }
    sequence(:y) { |n| n }
    zone { "Starter Plains" }
    biome { "plains" }
    resource_key { "iron_ore" }
    resource_type { "ore" }
    quantity { 1 }
    base_quantity { 1 }
    metadata { {} }

    trait :depleted do
      quantity { 0 }
      respawns_at { 25.minutes.from_now }
    end

    trait :ready_to_respawn do
      quantity { 0 }
      respawns_at { 5.minutes.ago }
    end

    trait :with_harvester do
      association :harvested_by, factory: :character
      last_harvested_at { 10.minutes.ago }
    end

    trait :forest_herb do
      biome { "forest" }
      resource_key { "moonleaf_herb" }
      resource_type { "herb" }
    end

    trait :mountain_ore do
      biome { "mountain" }
      resource_key { "gold_vein" }
      resource_type { "ore" }
      metadata { {"rarity" => "uncommon"} }
    end

    trait :rare_resource do
      resource_key { "crystal_formation" }
      resource_type { "crystal" }
      metadata { {"rarity" => "rare"} }
    end
  end
end

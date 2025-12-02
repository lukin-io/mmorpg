# frozen_string_literal: true

FactoryBot.define do
  factory :tile_npc do
    sequence(:x) { |n| n }
    sequence(:y) { |n| n }
    zone { "Starter Plains" }
    biome { "plains" }
    npc_key { "wild_boar" }
    npc_role { "hostile" }
    level { 2 }
    current_hp { 80 }
    max_hp { 80 }
    metadata { {} }
    association :npc_template

    trait :defeated do
      current_hp { 0 }
      defeated_at { 10.minutes.ago }
      respawns_at { 20.minutes.from_now }
      association :defeated_by, factory: :character
    end

    trait :ready_to_respawn do
      current_hp { 0 }
      defeated_at { 35.minutes.ago }
      respawns_at { 5.minutes.ago }
      association :defeated_by, factory: :character
    end

    trait :friendly do
      npc_key { "wandering_merchant" }
      npc_role { "vendor" }
      level { 5 }
    end

    trait :forest do
      biome { "forest" }
      npc_key { "forest_wolf" }
      level { 3 }
      current_hp { 70 }
      max_hp { 70 }
    end

    trait :elite do
      npc_key { "mountain_troll" }
      npc_role { "hostile" }
      level { 10 }
      current_hp { 300 }
      max_hp { 300 }
      metadata { {"rarity" => "rare"} }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :tile_npc do
    sequence(:x) { |n| n }
    sequence(:y) { |n| n }
    zone { "Outpost Surroundings" }
    npc_key { "plague_rat" }
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

    trait :outdoor do
      npc_key { "plague_rat" }
      level { 4 }
      current_hp { 100 }
      max_hp { 100 }
    end

    trait :at_region_edge do
      x { 999 }
      y { 999 }
    end

    trait :without_combat_health do
      current_hp { 0 }
      max_hp { 0 }
    end

    trait :multi_npc_encounter do
      metadata { {"encounter_count" => 2} }
    end

    trait :single_npc_encounter do
      metadata { {"encounter_count" => 1} }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :tile_building do
    zone { "Starter Plains" }
    sequence(:x) { |n| n % 100 }
    sequence(:y) { |n| (n / 100) % 100 }
    sequence(:building_key) { |n| "building_#{n}" }
    building_type { "castle" }
    name { "Test Building" }
    destination_zone { nil }
    destination_x { nil }
    destination_y { nil }
    icon { "🏰" }
    required_level { 1 }
    faction_key { nil }
    metadata { {} }
    active { true }

    trait :with_destination do
      association :destination_zone, factory: :zone
      destination_x { 5 }
      destination_y { 5 }
    end

    trait :castle do
      building_type { "castle" }
      icon { "🏰" }
    end

    trait :fort do
      building_type { "fort" }
      icon { "🏯" }
    end

    trait :inn do
      building_type { "inn" }
      icon { "🏨" }
    end

    trait :shop do
      building_type { "shop" }
      icon { "🏪" }
    end

    trait :dungeon_entrance do
      building_type { "dungeon_entrance" }
      icon { "⚔️" }
    end

    trait :portal do
      building_type { "portal" }
      icon { "🌀" }
    end

    trait :inactive do
      active { false }
    end

    trait :high_level do
      required_level { 50 }
    end

    trait :faction_restricted do
      faction_key { "alliance" }
    end
  end
end

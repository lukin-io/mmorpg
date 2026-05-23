# frozen_string_literal: true

FactoryBot.define do
  factory :tile_building do
    zone { "Outpost Surroundings" }
    sequence(:x) { |n| n % 100 }
    sequence(:y) { |n| (n / 100) % 100 }
    sequence(:building_key) { |n| "building_#{n}" }
    building_type { "city" }
    name { "Test Building" }
    destination_zone { nil }
    destination_x { nil }
    destination_y { nil }
    icon { "🏙️" }
    required_level { 1 }
    metadata { {} }
    active { true }

    trait :with_destination do
      association :destination_zone, factory: :zone
      destination_x { 5 }
      destination_y { 5 }
    end

    trait :shop do
      building_type { "shop" }
      icon { "🏪" }
    end

    trait :arena do
      building_type { "arena" }
      icon { "⚔️" }
    end

    trait :inactive do
      active { false }
    end

    trait :high_level do
      required_level { 50 }
    end
  end
end

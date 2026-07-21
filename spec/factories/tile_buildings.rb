# frozen_string_literal: true

FactoryBot.define do
  factory :tile_building do
    zone { "Outpost Surroundings" }
    sequence(:x) { |n| n % 100 }
    sequence(:y) { |n| (n / 100) % 100 }
    sequence(:building_key) { |n| "city_gate_#{n}" }
    building_type { "city" }
    name { "West Gate" }
    association :destination_zone, factory: [:zone, :city]
    destination_x { 0 }
    destination_y { 0 }
    icon { nil }
    required_level { 1 }
    metadata { {} }
    active { true }

    trait :without_destination do
      destination_zone { nil }
      destination_x { nil }
      destination_y { nil }
    end

    trait :without_destination_coordinates do
      destination_x { nil }
      destination_y { nil }
    end

    trait :inactive do
      active { false }
    end
  end
end

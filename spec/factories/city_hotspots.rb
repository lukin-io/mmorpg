# frozen_string_literal: true

FactoryBot.define do
  factory :city_hotspot do
    zone
    sequence(:key) { |n| "hotspot_#{n}" }
    name { "Test Building" }
    hotspot_type { "building" }
    position_x { 100 }
    position_y { 100 }
    image_normal { "test_building.png" }
    image_hover { "test_building_hl.png" }
    action_type { "open_feature" }
    action_params { {"feature" => "test"} }
    required_level { 1 }
    active { true }
    z_index { 0 }

    trait :building do
      hotspot_type { "building" }
      action_type { "open_feature" }
    end

    trait :exit do
      hotspot_type { "exit" }
      action_type { "enter_zone" }
      association :destination_zone, factory: :zone
    end

    trait :decoration do
      hotspot_type { "decoration" }
      action_type { "none" }
      image_hover { nil }
    end

    trait :feature do
      hotspot_type { "feature" }
      action_type { "open_feature" }
    end

    trait :inactive do
      active { false }
    end

    trait :high_level do
      required_level { 50 }
    end

    trait :arena do
      key { "arena" }
      name { "Arena" }
      hotspot_type { "building" }
      action_type { "open_feature" }
      action_params { {"feature" => "arena"} }
      image_normal { "arena.png" }
    end

    trait :workshop do
      key { "workshop" }
      name { "Workshop" }
      hotspot_type { "building" }
      action_type { "open_feature" }
      action_params { {"feature" => "crafting"} }
      image_normal { "workshop.png" }
    end

    trait :city_gate do
      key { "city_gate" }
      name { "City Gates" }
      hotspot_type { "exit" }
      action_type { "enter_zone" }
      association :destination_zone, factory: :zone
      image_normal { "gate.png" }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :city_hotspot do
    zone
    sequence(:key) { |n| "hotspot_#{n}" }
    name { "Arena" }
    hotspot_type { "building" }
    position_x { 0 }
    position_y { 0 }
    width { nil }
    height { nil }
    action_type { "open_feature" }
    action_params { {"feature" => "arena"} }
    required_level { 0 }
    active { true }
    z_index { 0 }

    trait :building do
      hotspot_type { "building" }
      action_type { "open_feature" }
    end

    trait :exit do
      name { "West Gate" }
      hotspot_type { "exit" }
      action_type { "enter_zone" }
      association :destination_zone, factory: :zone
      action_params { {"destination_x" => 0, "destination_y" => 0} }
    end

    trait :district do
      name { "Business Quarter" }
      hotspot_type { "district" }
      action_type { "enter_zone" }
      association :destination_zone, factory: [:zone, :city]
      action_params { {"destination_x" => 0, "destination_y" => 0} }
    end

    trait :inactive do
      active { false }
    end

    trait :high_level do
      required_level { 50 }
    end

    trait :starter_accessible do
      required_level { 0 }
    end

    trait :arena do
      key { "arena" }
      name { "Arena" }
      hotspot_type { "building" }
      action_type { "open_feature" }
      action_params { {"feature" => "arena"} }
    end

    trait :shop do
      key { "shop" }
      name { "Shop" }
      hotspot_type { "building" }
      action_type { "open_feature" }
      action_params { {"feature" => "shop"} }
    end

    trait :city_gate do
      key { "city_gate" }
      name { "Outpost Gate" }
      hotspot_type { "exit" }
      action_type { "enter_zone" }
      association :destination_zone, factory: :zone
      action_params { {"destination_x" => 7, "destination_y" => 0} }
    end


    trait :read_only_city_building do
      key { "market" }
      name { "Market" }
      hotspot_type { "building" }
      action_type { "open_feature" }
      action_params { {"feature" => "market"} }
    end
  end
end

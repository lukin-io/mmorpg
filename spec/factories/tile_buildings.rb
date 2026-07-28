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

    trait :world_location do
      building_type { "location" }
      name { "Frontier Village" }
      destination_zone { nil }
      destination_x { nil }
      destination_y { nil }
      metadata do
        {
          "landmark_kind" => "village",
          "location" => {
            "short_label" => "Village",
            "kind" => "village",
            "scene" => {"width" => 760, "height" => 255},
            "features" => [
              {
                "key" => "trading_post",
                "label" => "Trading Post",
                "action_type" => "open_feature",
                "feature" => "shop",
                "polygon" => [[85, 146], [238, 180], [205, 196], [86, 154]]
              },
              {
                "key" => "exit",
                "label" => "Leave the village",
                "action_type" => "return_world",
                "polygon" => [[527, 235], [577, 239], [561, 218], [536, 210]]
              }
            ]
          }
        }
      end
    end
  end
end

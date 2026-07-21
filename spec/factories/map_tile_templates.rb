# frozen_string_literal: true

FactoryBot.define do
  factory :map_tile_template do
    sequence(:zone) { |n| "Zone #{n}" }
    sequence(:x) { |n| n % 10 }
    sequence(:y) { |n| n / 10 }
    terrain_type { "outdoor" }
    passable { true }
    metadata { {} }

    trait :blocked do
      passable { false }
      metadata { {"blocked" => true} }
    end

    trait :with_resource_search do
      metadata do
        {
          "local_actions" => [
            {
              "type" => "resource_search",
              "source_id" => "look",
              "label" => "Look Around",
              "description" => "Search for herbs and local resources."
            }
          ]
        }
      end
    end

    trait :with_cell_art do
      metadata do
        {
          "source_map" => "m_1001_999",
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => 7,
            "row" => 7
          }
        }
      end
    end

    trait :with_invalid_cell_art do
      metadata do
        {
          "source_map" => "m_unknown",
          "cell_art" => {
            "key" => "unknown_art",
            "column" => 0,
            "row" => 0
          }
        }
      end
    end

    trait :with_cell_art_at_sheet_edge do
      metadata do
        {
          "source_map" => "m_sheet_edge",
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => 9,
            "row" => 9
          }
        }
      end
    end

    trait :with_fishing do
      metadata do
        {
          "local_actions" => [
            {
              "type" => "fishing",
              "source_id" => "fis",
              "label" => "Fish"
            }
          ]
        }
      end
    end

    trait :with_inactive_resource_search do
      metadata do
        {
          "local_actions" => [
            {
              "type" => "resource_search",
              "source_id" => "look",
              "label" => "Look Around",
              "active" => false
            }
          ]
        }
      end
    end

    trait :at_boundary do
      x { 0 }
      y { 0 }
    end

    trait :at_region_edge do
      x { 999 }
      y { 999 }
    end
  end
end

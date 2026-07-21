FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    location_type { "outdoor" }
    width { 10 }
    height { 10 }
    metadata { {} }

    trait :mvp_outdoor_region do
      location_type { "outdoor" }
      width { 1000 }
      height { 1000 }
    end

    trait :city do
      location_type { "city" }
    end

    trait :city_node do
      location_type { "city" }
      metadata do
        {
          "city_key" => "forpost",
          "city_node_key" => "city2_1",
          "title" => "Central Square"
        }
      end
    end

    trait :minimum_size do
      width { 1 }
      height { 1 }
    end
  end
end

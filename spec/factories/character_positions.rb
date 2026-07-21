FactoryBot.define do
  factory :character_position do
    association :character
    association :zone
    x { 0 }
    y { 0 }
    state { :active }
    last_turn_number { 0 }

    trait :at_origin do
      x { 0 }
      y { 0 }
    end

    trait :at_region_edge do
      x { 999 }
      y { 999 }
      association :zone, factory: [:zone, :mvp_outdoor_region]
    end

    trait :outside_region do
      x { 1000 }
      y { 1000 }
      association :zone, factory: [:zone, :mvp_outdoor_region]
    end
  end
end

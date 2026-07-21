# frozen_string_literal: true

FactoryBot.define do
  factory :world_action_offer do
    association :character
    association :zone
    x { 5 }
    y { 5 }
    action_type { "attack_npc" }
    action_key { SecureRandom.hex(16) }
    status { :offered }
    expires_at { 10.minutes.from_now }
    metadata { {} }

    trait :accepted do
      status { :accepted }
      accepted_at { Time.current }
    end

    trait :completed do
      status { :completed }
      accepted_at { 1.minute.ago }
      completed_at { Time.current }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :resource_search do
      action_type { "search_resources" }
      association :target, factory: [:map_tile_template, :with_resource_search]
      metadata { {"local_action_type" => "resource_search", "source_id" => "look"} }
    end

    trait :without_target do
      target { nil }
    end

    trait :at_region_edge do
      association :zone, factory: [:zone, :mvp_outdoor_region]
      x { 999 }
      y { 999 }
    end

    trait :city_transition do
      action_type { "city_transition" }
      association :target, factory: [:city_hotspot, :district]
    end

    trait :city_building_entry do
      action_type { "enter_city_building" }
      association :target, factory: [:city_hotspot, :read_only_city_building]
    end
  end
end

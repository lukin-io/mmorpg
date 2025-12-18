# frozen_string_literal: true

FactoryBot.define do
  factory :arena_room do
    sequence(:name) { |n| "Arena Room #{n}" }
    sequence(:slug) { |n| "arena-room-#{n}" }
    room_type { :training }
    level_min { 1 }
    level_max { 100 }
    max_concurrent_matches { 10 }
    active { true }
    faction_restriction { nil }

    trait :training do
      room_type { :training }
      level_min { 0 }
      level_max { 5 }
    end

    trait :trial do
      room_type { :trial }
      level_min { 5 }
      level_max { 10 }
    end

    trait :standard do
      room_type { :challenge }
      level_min { 1 }
      level_max { 100 }
    end

    trait :high_level do
      room_type { :patron }
      level_min { 50 }
      level_max { 100 }
    end

    trait :inactive do
      active { false }
    end

    trait :law_faction do
      room_type { :law }
      faction_restriction { "alliance" }
    end
  end
end

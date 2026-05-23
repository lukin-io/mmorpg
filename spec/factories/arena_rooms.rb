# frozen_string_literal: true

FactoryBot.define do
  factory :arena_room do
    sequence(:name) { |n| "Тренировочный Зал #{n}" }
    sequence(:slug) { |n| "training-room-#{n}" }
    room_type { :training }
    level_min { 1 }
    level_max { 100 }
    max_concurrent_matches { 10 }
    active { true }
    alignment_restriction { nil }

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
      room_type { :trial }
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

    trait :law_alignment do
      room_type { :law }
      alignment_restriction { "law" }
    end
  end
end

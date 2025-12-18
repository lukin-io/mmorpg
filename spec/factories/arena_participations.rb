# frozen_string_literal: true

FactoryBot.define do
  factory :arena_participation do
    association :arena_match
    association :character
    association :user
    team { "a" }
    result { :pending }
    joined_at { Time.current }

    trait :team_a do
      team { "a" }
    end

    trait :team_b do
      team { "b" }
    end

    trait :pending do
      result { :pending }
    end

    trait :victory do
      result { :victory }
    end

    trait :defeat do
      result { :defeat }
    end

    trait :draw do
      result { :draw }
    end
  end
end

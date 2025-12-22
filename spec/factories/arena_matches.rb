# frozen_string_literal: true

FactoryBot.define do
  factory :arena_match do
    match_type { :duel }
    status { :pending }
    spectator_code { SecureRandom.alphanumeric(8).upcase }

    trait :duel do
      match_type { :duel }
    end

    trait :team_battle do
      match_type { :team_battle }
    end

    trait :sacrifice do
      match_type { :sacrifice }
    end

    trait :pending do
      status { :pending }
    end

    trait :live do
      status { :live }
      started_at { Time.current }
    end

    trait :completed do
      status { :completed }
      started_at { 10.minutes.ago }
      ended_at { Time.current }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end

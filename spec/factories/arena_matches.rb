# frozen_string_literal: true

FactoryBot.define do
  factory :arena_match do
    match_type { :duel }
    status { :pending }
    metadata { {} }

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

    trait :countdown do
      status { :pending }
      metadata { {"starts_at" => 10.seconds.from_now.iso8601} }
    end

    trait :countdown_due do
      status { :pending }
      metadata { {"starts_at" => 1.second.ago.iso8601} }
    end

    trait :live do
      status { :live }
      started_at { Time.current }
      current_turn_started_at { Time.current }
      current_turn_number { 1 }
    end

    trait :timeout_claimable do
      live
      turn_timeout_seconds { 300 }
      current_turn_started_at { 301.seconds.ago }
    end

    trait :completed do
      status { :completed }
      started_at { 10.minutes.ago }
      ended_at { Time.current }
    end

    trait :drawn do
      completed
      winning_team { nil }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end

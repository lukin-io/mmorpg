# frozen_string_literal: true

FactoryBot.define do
  factory :arena_application do
    association :arena_room
    association :applicant, factory: :character
    fight_type { :duel }
    fight_kind { :free }
    status { :open }
    timeout_seconds { 180 }
    trauma_percent { 30 }
    wait_minutes { 10 }
    expires_at { 10.minutes.from_now }

    trait :open do
      status { :open }
    end

    trait :matched do
      status { :matched }
      starts_at { 30.seconds.from_now }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.minute.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :duel do
      fight_type { :duel }
    end

    trait :team_battle do
      fight_type { :team_battle }
      team_count { 2 }
      enemy_count { 2 }
    end

    trait :sacrifice do
      fight_type { :sacrifice }
    end
  end
end

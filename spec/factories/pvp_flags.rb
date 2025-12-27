# frozen_string_literal: true

FactoryBot.define do
  factory :pvp_flag do
    association :character
    flag_type { :voluntary }
    expires_at { nil }
    source { "manual" }
    metadata { {} }

    trait :voluntary do
      flag_type { :voluntary }
      expires_at { nil }
    end

    trait :hostile_action do
      flag_type { :hostile_action }
      expires_at { 5.minutes.from_now }
      source { "attacked_player" }
    end

    trait :zone_flag do
      flag_type { :zone_flag }
      expires_at { nil }
      source { "entered_pvp_zone" }
    end

    trait :faction_war do
      flag_type { :faction_war }
      expires_at { 10.minutes.from_now }
      source { "faction_event" }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :expiring_soon do
      expires_at { 30.seconds.from_now }
    end
  end
end

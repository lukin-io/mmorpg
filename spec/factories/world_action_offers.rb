# frozen_string_literal: true

FactoryBot.define do
  factory :world_action_offer do
    association :character
    association :zone
    x { 5 }
    y { 5 }
    action_type { "gather_resource" }
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
  end
end

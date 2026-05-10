FactoryBot.define do
  factory :movement_command do
    association :character
    association :zone
    direction { "north" }
    status { :queued }
    metadata { {} }

    trait :offered do
      status { :offered }
      from_x { 5 }
      from_y { 5 }
      target_x { 5 }
      target_y { 4 }
      predicted_x { target_x }
      predicted_y { target_y }
      action_key { SecureRandom.hex(16) }
      travel_seconds { 30 }
    end

    trait :moving do
      offered
      status { :moving }
      started_at { Time.current }
      ends_at { 30.seconds.from_now }
    end

    trait :completed do
      moving
      status { :completed }
      completed_at { Time.current }
      processed_at { Time.current }
    end
  end
end

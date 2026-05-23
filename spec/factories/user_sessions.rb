FactoryBot.define do
  factory :user_session do
    association :user
    sequence(:device_id) { |n| "device-#{n}" }
    signed_in_at { Time.current }
    last_seen_at { Time.current }
  end
end

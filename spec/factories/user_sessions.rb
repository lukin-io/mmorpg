FactoryBot.define do
  factory :user_session do
    association :user
    sequence(:device_id) { |n| "device-#{n}" }
    user_agent { "RSpec" }
    ip_address { "127.0.0.1" }
    status { "online" }
    signed_in_at { Time.current }
    last_seen_at { Time.current }
    metadata { {} }
  end
end

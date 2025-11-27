# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_event do
    association :webhook_endpoint
    event_type { "player.level_up" }
    payload { {test: true}.to_json }
    status { "pending" }
    delivery_attempts { 0 }
  end
end

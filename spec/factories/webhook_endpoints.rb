# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_endpoint do
    association :integration_token
    sequence(:name) { |n| "Webhook Endpoint #{n}" }
    target_url { "https://example.com/webhook" }
    secret { SecureRandom.hex(32) }
    enabled { true }
    event_types { ["player.level_up", "achievement.unlocked"] }
  end
end

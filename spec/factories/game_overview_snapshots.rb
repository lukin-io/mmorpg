FactoryBot.define do
  factory :game_overview_snapshot do
    captured_at { Time.current }
    daily_returning_players { 10 }
    weekly_returning_players { 50 }
    chat_senders_7d { 25 }
    active_guilds_7d { 5 }
    active_clans_7d { 3 }
    seasonal_events_active { 1 }
    premium_purchases_30d { 12 }
    avg_tokens_per_paying_user { 42.5 }
    whale_share_percent { 55.0 }
  end
end

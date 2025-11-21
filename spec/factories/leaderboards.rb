FactoryBot.define do
  factory :leaderboard do
    sequence(:name) { |n| "Leaderboard #{n}" }
    scope { "pvp" }
    season { "1" }
    starts_at { 1.day.ago }
    ends_at { 1.day.from_now }
  end
end

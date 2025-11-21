FactoryBot.define do
  factory :game_event do
    sequence(:name) { |n| "Event #{n}" }
    slug { name.parameterize }
    description { "Seasonal fun" }
    status { :upcoming }
    starts_at { 1.day.from_now }
    ends_at { 2.days.from_now }
  end
end

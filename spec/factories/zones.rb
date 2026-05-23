FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    location_type { "outdoor" }
    width { 10 }
    height { 10 }
    metadata { {} }
  end
end

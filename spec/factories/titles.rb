FactoryBot.define do
  factory :title do
    sequence(:name) { |n| "Champion #{n}" }
    requirement_key { "achievement_#{SecureRandom.hex(2)}" }
    perks { {} }
  end
end

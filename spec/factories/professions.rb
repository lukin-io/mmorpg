FactoryBot.define do
  factory :profession do
    sequence(:name) { |n| "Profession #{n}" }
    category { "production" }
    description { "Profession description" }
    gathering { false }
    healing_bonus { 0 }
    metadata { {} }
  end
end

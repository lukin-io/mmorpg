FactoryBot.define do
  factory :character_class do
    sequence(:name) { |n| "Class #{n}" }
    description { "Balanced archetype" }
    base_stats { {strength: 10, agility: 10, intellect: 10} }
  end
end

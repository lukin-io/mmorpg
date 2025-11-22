FactoryBot.define do
  factory :skill_tree do
    association :character_class
    sequence(:name) { |n| "Skill Tree #{n}" }
    description { "Tree description" }
    metadata { {} }
  end
end


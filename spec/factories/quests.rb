FactoryBot.define do
  factory :quest do
    association :quest_chain
    sequence(:key) { |n| "quest_#{n}" }
    sequence(:title) { |n| "Quest #{n}" }
    summary { "Save the realm" }
    quest_type { :main_story }
    sequence(:sequence) { |n| n }
    chapter { 1 }
    requirements { {} }
    rewards { {} }
    metadata { {} }
  end
end

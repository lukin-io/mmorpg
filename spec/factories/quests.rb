FactoryBot.define do
  factory :quest do
    association :quest_chain
    quest_chapter { association :quest_chapter, quest_chain: quest_chain }
    sequence(:key) { |n| "quest_#{n}" }
    sequence(:title) { |n| "Quest #{n}" }
    summary { "Save the realm" }
    quest_type { :main_story }
    sequence(:sequence) { |n| n }
    chapter { 1 }
    difficulty_tier { :story }
    recommended_party_size { 1 }
    min_level { 1 }
    min_reputation { 0 }
    requirements { {} }
    rewards { {} }
    metadata { {} }
  end
end

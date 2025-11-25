FactoryBot.define do
  factory :quest_chapter do
    association :quest_chain
    sequence(:key) { |n| "chapter_#{n}" }
    sequence(:title) { |n| "Chapter #{n}" }
    sequence(:position) { |n| n }
    level_gate { 1 }
    reputation_gate { 0 }
    metadata { {} }
  end
end

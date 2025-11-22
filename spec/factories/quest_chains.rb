FactoryBot.define do
  factory :quest_chain do
    sequence(:key) { |n| "chain_#{n}" }
    sequence(:title) { |n| "Quest Chain #{n}" }
    description { "Story arc" }
  end
end

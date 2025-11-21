FactoryBot.define do
  factory :character do
    association :user
    association :character_class
    sequence(:name) { |n| "Hero#{n}" }
    level { 1 }
    experience { 0 }
  end
end

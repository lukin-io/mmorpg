FactoryBot.define do
  factory :character_skill do
    association :character
    association :skill_node
    unlocked_at { Time.current }
  end
end

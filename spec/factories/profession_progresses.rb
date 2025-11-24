FactoryBot.define do
  factory :profession_progress do
    association :character
    user { character.user }
    profession
    slot_kind { profession.slot_kind }
    skill_level { 1 }
    experience { 0 }
    mastery_tier { 0 }
  end
end

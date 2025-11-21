FactoryBot.define do
  factory :profession_progress do
    user
    profession
    skill_level { 1 }
    experience { 0 }
  end
end

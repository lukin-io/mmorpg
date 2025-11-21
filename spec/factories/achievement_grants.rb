FactoryBot.define do
  factory :achievement_grant do
    association :user
    association :achievement
    source { "spec" }
    granted_at { Time.current }
  end
end

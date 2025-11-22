FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "player#{n}@neverlands.test" }
    sequence(:profile_name) { |n| "player#{n}" }
    password { "Password123!" }
    password_confirmation { password }
    confirmed_at { Time.current }

    trait :moderator do
      after(:create) { |user| user.add_role(:moderator) }
    end
  end
end

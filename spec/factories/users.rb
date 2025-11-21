FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "player#{n}@neverlands.test" }
    password { "Password123!" }
    password_confirmation { password }
    confirmed_at { Time.current }
  end
end

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "player#{n}@neverlands.test" }
    password { "Password123!" }
    password_confirmation { password }
  end
end

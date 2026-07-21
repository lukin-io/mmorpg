FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "player#{n}@browser-rpg.test" }
    sequence(:profile_name) { |n| "player#{n}" }
    password { "Password123!" }
    password_confirmation { password }
    confirmed_at { Time.current }

    trait :moderator do
      after(:create) { |user| user.add_role(:moderator) }
    end

    trait :with_fractional_nv_balance do
      after(:create) { |user| user.currency_wallet.update!(nv_balance: BigDecimal("12.50")) }
    end

    trait :with_maximum_nv_balance do
      after(:create) { |user| user.currency_wallet.update!(nv_balance: BigDecimal("9999999999.99")) }
    end
  end
end

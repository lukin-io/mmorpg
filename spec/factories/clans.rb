FactoryBot.define do
  factory :clan do
    sequence(:name) { |n| "Clan #{n}" }
    slug { name.parameterize }
    leader { association :user }
  end
end

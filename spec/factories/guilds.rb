FactoryBot.define do
  factory :guild do
    sequence(:name) { |n| "Guild #{n}" }
    slug { name.parameterize }
    leader { association :user }
  end
end

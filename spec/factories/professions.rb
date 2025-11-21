FactoryBot.define do
  factory :profession do
    sequence(:name) { |n| "Profession #{n}" }
    category { "production" }
  end
end

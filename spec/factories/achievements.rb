FactoryBot.define do
  factory :achievement do
    sequence(:key) { |n| "achievement_#{n}" }
    sequence(:name) { |n| "Achievement #{n}" }
    points { 10 }
  end
end

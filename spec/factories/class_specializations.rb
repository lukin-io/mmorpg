FactoryBot.define do
  factory :class_specialization do
    association :character_class
    sequence(:name) { |n| "Specialization #{n}" }
    description { "Advanced training" }
    unlock_requirements { {quest: "heroic_trial"} }
  end
end


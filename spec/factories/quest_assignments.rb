FactoryBot.define do
  factory :quest_assignment do
    association :quest
    association :character
    status { :pending }
    progress { {} }
    metadata { {} }
  end
end

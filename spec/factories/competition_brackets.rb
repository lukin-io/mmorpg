FactoryBot.define do
  factory :competition_bracket do
    association :game_event
    status { :seeding }
    metadata { {} }
  end
end

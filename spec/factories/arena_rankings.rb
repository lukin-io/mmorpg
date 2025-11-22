FactoryBot.define do
  factory :arena_ranking do
    association :character
    rating { 1200 }
    wins { 0 }
    losses { 0 }
    streak { 0 }
    ladder_metadata { {} }
  end
end

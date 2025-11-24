FactoryBot.define do
  factory :crafting_job do
    association :character
    user { character.user }
    recipe
    crafting_station
    status { :queued }
    started_at { Time.current }
    completes_at { 5.minutes.from_now }
    success_chance { 75 }
    quality_tier { "common" }
    quality_score { 50 }
    portable_penalty_applied { false }
    batch_quantity { 1 }
  end
end

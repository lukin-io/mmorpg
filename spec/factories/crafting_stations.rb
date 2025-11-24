FactoryBot.define do
  factory :crafting_station do
    sequence(:name) { |n| "Forge #{n}" }
    city { "Capital" }
    station_type { "forge" }
    capacity { 2 }
    station_archetype { "city" }
    time_penalty_multiplier { 1.0 }
    success_penalty { 0 }
    portable { false }
  end
end

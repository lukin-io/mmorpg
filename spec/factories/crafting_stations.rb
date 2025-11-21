FactoryBot.define do
  factory :crafting_station do
    sequence(:name) { |n| "Forge #{n}" }
    city { "Capital" }
    station_type { "forge" }
  end
end

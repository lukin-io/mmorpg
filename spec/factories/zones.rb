FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    biome { "plains" }
    width { 10 }
    height { 10 }
    encounter_table { {} }
    metadata { {} }
  end
end


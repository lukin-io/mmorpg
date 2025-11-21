FactoryBot.define do
  factory :pet_species do
    sequence(:name) { |n| "Pet #{n}" }
    ability_type { "buff" }
    ability_payload { {"bonus" => 0.05} }
    rarity { "common" }
  end
end

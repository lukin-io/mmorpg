FactoryBot.define do
  factory :ability do
    association :character_class
    sequence(:name) { |n| "Ability #{n}" }
    kind { "active" }
    resource_cost { {"mana" => 10} }
    cooldown_seconds { 5 }
    effects { {"status" => "burn"} }
    combo_tags { [] }
  end
end


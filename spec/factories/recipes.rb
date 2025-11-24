FactoryBot.define do
  factory :recipe do
    profession
    sequence(:name) { |n| "Recipe #{n}" }
    tier { 1 }
    duration_seconds { 60 }
    output_item_name { "Potion" }
    requirements { {"skill_level" => 1} }
    rewards { {"items" => [{"name" => "Potion", "quantity" => 1}]} }
    source_kind { "quest" }
    risk_level { "safe" }
    required_station_archetype { "city" }
    premium_token_cost { 0 }
    quality_modifiers { {} }
    guild_bound { false }
  end
end

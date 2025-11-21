FactoryBot.define do
  factory :recipe do
    profession
    sequence(:name) { |n| "Recipe #{n}" }
    tier { 1 }
    duration_seconds { 60 }
    output_item_name { "Potion" }
    requirements { {"skill_level" => 1} }
    rewards { {"items" => [{"name" => "Potion", "quantity" => 1}]} }
  end
end

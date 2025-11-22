FactoryBot.define do
  factory :item_template do
    sequence(:name) { |n| "Item #{n}" }
    slot { "weapon" }
    rarity { "common" }
    stat_modifiers { {attack: 5} }
    weight { 2 }
    stack_limit { 10 }
    premium { false }
    enhancement_rules { {"base_success_chance" => 60, "required_skill_level" => 1} }
  end
end


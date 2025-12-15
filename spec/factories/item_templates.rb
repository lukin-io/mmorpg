FactoryBot.define do
  factory :item_template do
    sequence(:name) { |n| "Item #{n}" }
    slot { "main_hand" }
    item_type { "equipment" }
    rarity { "common" }
    stat_modifiers { {"attack" => 5} }
    weight { 2 }
    stack_limit { 10 }
    premium { false }
    enhancement_rules { {"base_success_chance" => 60, "required_skill_level" => 1} }

    trait :material do
      item_type { "material" }
      slot { "none" }
      stat_modifiers { {} }
    end

    trait :consumable do
      item_type { "consumable" }
      slot { "none" }
      stat_modifiers { {"heal_hp" => 50} }
    end

    trait :armor do
      slot { "chest" }
      stat_modifiers { {"defense" => 10} }
    end
  end
end

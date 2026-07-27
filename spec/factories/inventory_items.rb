FactoryBot.define do
  factory :inventory_item do
    association :inventory
    association :item_template
    quantity { 1 }
    weight { item_template.weight }
    bound { false }
    properties { {} }

    trait :equipped do
      equipped { true }
      equipment_slot { item_template.slot }
    end

    trait :broken do
      properties { {"current_durability" => 0} }
    end
  end
end

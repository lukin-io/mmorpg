FactoryBot.define do
  factory :inventory_item do
    association :inventory
    association :item_template
    quantity { 1 }
    weight { item_template.weight }
    bound { false }
    properties { {} }
  end
end

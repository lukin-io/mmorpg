FactoryBot.define do
  factory :inventory_item do
    association :inventory
    association :item_template
    quantity { 1 }
    weight { item_template.weight }
    enhancement_level { 0 }
    premium { item_template.premium }
    bound { false }
    properties { {} }
  end
end


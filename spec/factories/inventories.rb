FactoryBot.define do
  factory :inventory do
    association :character
    slot_capacity { 30 }
    weight_capacity { 100 }
    current_weight { 0 }
    metadata { {} }
    currency_storage { {} }
  end
end


FactoryBot.define do
  factory :battle do
    association :initiator, factory: :character
    battle_type { :pve }
    status { :active }
    turn_number { 1 }
    initiative_order { [] }
    metadata { {} }
  end
end

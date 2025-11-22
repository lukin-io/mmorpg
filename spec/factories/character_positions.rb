FactoryBot.define do
  factory :character_position do
    association :character
    association :zone
    x { 0 }
    y { 0 }
    state { :active }
    last_turn_number { 0 }
  end
end


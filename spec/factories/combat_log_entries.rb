FactoryBot.define do
  factory :combat_log_entry do
    association :battle
    round_number { 1 }
    sequence(:sequence) { |n| n }
    message { "Attack landed" }
    payload { {damage: 10} }
  end
end


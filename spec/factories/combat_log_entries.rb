FactoryBot.define do
  factory :combat_log_entry do
    association :arena_match
    round_number { 1 }
    sequence(:sequence) { |n| n }
    log_type { "action" }
    message { "Attack landed" }
    payload { {damage: 10} }
  end
end

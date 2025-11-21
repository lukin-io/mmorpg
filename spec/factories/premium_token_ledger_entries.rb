FactoryBot.define do
  factory :premium_token_ledger_entry do
    association :user
    entry_type { "purchase" }
    delta { 10 }
    balance_after { 10 }
    metadata { {} }
  end
end

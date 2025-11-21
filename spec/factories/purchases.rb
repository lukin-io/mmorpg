FactoryBot.define do
  factory :purchase do
    association :user
    provider { "stripe" }
    sequence(:external_id) { |n| "pi_#{n}" }
    status { "pending" }
    amount_cents { 500 }
    currency { "USD" }
    metadata { { "token_amount" => 50 } }
  end
end

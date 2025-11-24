FactoryBot.define do
  factory :trade_item do
    association :trade_session
    owner { trade_session.initiator }
    item_name { "Wolf Pelt" }
    quantity { 1 }
  end
end

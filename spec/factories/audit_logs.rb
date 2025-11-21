FactoryBot.define do
  factory :audit_log do
    association :actor, factory: :user
    action { "test.action" }
    metadata { {} }
  end
end

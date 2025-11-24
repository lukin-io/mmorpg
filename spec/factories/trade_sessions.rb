FactoryBot.define do
  factory :trade_session do
    association :initiator, factory: :user
    association :recipient, factory: :user
    status { :pending }
    expires_at { 15.minutes.from_now }
  end
end

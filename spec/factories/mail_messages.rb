FactoryBot.define do
  factory :mail_message do
    association :sender, factory: :user
    association :recipient, factory: :user
    subject { "Greetings" }
    body { "Welcome to Neverlands" }
    attachment_payload { {} }
    delivered_at { Time.current }
  end
end

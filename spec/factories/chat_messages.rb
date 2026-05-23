FactoryBot.define do
  factory :chat_message do
    association :chat_channel
    association :sender, factory: :user
    body { "Hello world" }
    visibility { :normal }
    metadata { {} }
  end
end

FactoryBot.define do
  factory :chat_message do
    association :chat_channel
    association :sender, factory: :user
    body { "Hello world" }
    filtered_body { body }
    visibility { :normal }
    flagged { false }
    metadata { {} }
  end
end

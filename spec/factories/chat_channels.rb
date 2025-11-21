FactoryBot.define do
  factory :chat_channel do
    sequence(:name) { |n| "Channel #{n}" }
    sequence(:slug) { |n| "channel-#{n}" }
    channel_type { :global }
  end
end

FactoryBot.define do
  factory :chat_moderation_action do
    association :target_user, factory: :user
    association :actor, factory: :user
    action_type { :mute_global }
    expires_at { 1.hour.from_now }
    context { {"reason" => "Spec mute"} }
  end
end

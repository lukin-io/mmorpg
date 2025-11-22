FactoryBot.define do
  factory :moderation_action, class: "Moderation::Action" do
    ticket { association :moderation_ticket }
    actor { association :user, :moderator }
    action_type { :warning }
    reason { "Please keep chat friendly" }
    metadata { {} }
  end
end

FactoryBot.define do
  factory :moderation_ticket, class: "Moderation::Ticket" do
    reporter { association :user }
    source { :chat }
    category { :chat_abuse }
    status { :open }
    priority { :normal }
    description { "Player used disallowed language in global chat." }
    evidence { {"log_excerpt" => "bad words"} }
    metadata { {"entry_point" => "chat"} }
  end
end

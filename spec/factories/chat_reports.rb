FactoryBot.define do
  factory :chat_report do
    reporter { association :user }
    reason { "Spam" }
    evidence { {"log_excerpt" => "buy gold"} }
  end
end

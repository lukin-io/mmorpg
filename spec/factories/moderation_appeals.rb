FactoryBot.define do
  factory :moderation_appeal, class: "Moderation::Appeal" do
    ticket { association :moderation_ticket }
    appellant { ticket.reporter }
    body { "Please reconsider, context was missing." }
    sla_due_at { 2.days.from_now }
  end
end

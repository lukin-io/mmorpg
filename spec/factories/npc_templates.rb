# frozen_string_literal: true

FactoryBot.define do
  factory :npc_template do
    sequence(:name) { |n| "NPC #{n}" }
    level { 1 }
    role { "hostile" }
    dialogue { "Greetings, traveler." }
    metadata { {} }
  end
end

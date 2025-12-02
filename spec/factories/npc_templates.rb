# frozen_string_literal: true

FactoryBot.define do
  factory :npc_template do
    sequence(:name) { |n| "NPC #{n}" }
    level { 1 }
    role { "hostile" }  # Must be one of ROLES: quest_giver, vendor, trainer, guard, innkeeper, banker, auctioneer, crafter, hostile, lore
    dialogue { "Greetings, traveler." }
    metadata { {} }
  end
end

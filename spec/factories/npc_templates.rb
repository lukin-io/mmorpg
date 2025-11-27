# frozen_string_literal: true

FactoryBot.define do
  factory :npc_template do
    sequence(:name) { |n| "NPC #{n}" }
    level { 1 }
    npc_type { "monster" }
    behavior { "hostile" }
    base_stats { {strength: 10, agility: 10, intelligence: 10} }
    loot_table { {} }
  end
end

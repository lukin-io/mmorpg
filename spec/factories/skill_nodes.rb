FactoryBot.define do
  factory :skill_node do
    association :skill_tree
    sequence(:key) { |n| "node_#{n}" }
    sequence(:name) { |n| "Skill Node #{n}" }
    node_type { "passive" }
    tier { 1 }
    requirements { {} }
    effects { {bonus: 5} }
    resource_cost { {} }
    cooldown_seconds { 0 }
  end
end


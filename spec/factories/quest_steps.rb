FactoryBot.define do
  factory :quest_step do
    association :quest
    sequence(:position) { |n| n }
    step_type { "dialogue" }
    npc_key { "npc_#{SecureRandom.hex(2)}" }
    content { {"dialogue" => "Hello adventurer."} }
    branching_outcomes { {"choices" => []} }
  end
end

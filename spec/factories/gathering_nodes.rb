FactoryBot.define do
  factory :gathering_node do
    association :profession
    association :zone
    sequence(:resource_key) { |n| "resource_#{n}" }
    difficulty { 1 }
    respawn_seconds { 30 }
    rewards { {"herb" => 1} }
  end
end


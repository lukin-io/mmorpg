FactoryBot.define do
  factory :spawn_point do
    association :zone
    x { 0 }
    y { 0 }
    faction_key { "neutral" }
    city_key { "starter" }
    respawn_seconds { 30 }
    default_entry { true }
    metadata { {} }
  end
end


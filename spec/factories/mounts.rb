FactoryBot.define do
  factory :mount do
    association :user
    name { "Swiftclaw #{SecureRandom.hex(2)}" }
    mount_type { "raptor" }
    speed_bonus { 15 }
    faction_key { "neutral" }
    rarity { "rare" }
    cosmetic_variant { "default" }
  end
end

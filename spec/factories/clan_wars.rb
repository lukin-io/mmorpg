FactoryBot.define do
  factory :clan_war do
    association :attacker_clan, factory: :clan
    association :defender_clan, factory: :clan
    territory_key { "ashen_forest" }
    scheduled_at { 1.hour.from_now }
    status { :scheduled }
  end
end

FactoryBot.define do
  factory :battle_participant do
    association :battle
    association :character
    role { "combatant" }
    team { "alpha" }
    initiative { 10 }
    hp_remaining { 100 }
    stat_snapshot { {hp: 100, attack: 10} }
    buffs { {} }
  end
end

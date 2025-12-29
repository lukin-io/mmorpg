FactoryBot.define do
  factory :battle_participant do
    association :battle
    association :character
    role { "combatant" }
    team { "alpha" }
    initiative { 10 }
    hp_remaining { 100 }
    current_hp { 100 }
    max_hp { 100 }
    stat_snapshot { {hp: 100, attack: 10, defense: 5} }
    buffs { {} }
    is_alive { true }
    is_defending { false }

    trait :alpha do
      team { "alpha" }
    end

    trait :beta do
      team { "beta" }
    end

    trait :dead do
      current_hp { 0 }
      hp_remaining { 0 }
      is_alive { false }
    end

    trait :low_hp do
      current_hp { 10 }
      hp_remaining { 10 }
    end

    trait :defending do
      is_defending { true }
    end

    trait :high_initiative do
      initiative { 50 }
    end

    trait :low_initiative do
      initiative { 1 }
    end
  end
end

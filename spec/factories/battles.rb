FactoryBot.define do
  factory :battle do
    association :initiator, factory: :character
    battle_type { :pve }
    status { :active }
    combat_mode { "simultaneous" }
    turn_number { 1 }
    initiative_order { [] }
    metadata { {} }
    action_points_per_turn { 80 }

    trait :active do
      status { :active }
    end

    trait :completed do
      status { :completed }
      ended_at { Time.current }
    end

    trait :pending do
      status { :pending }
    end

    trait :pvp do
      battle_type { :pvp }
      pvp_mode { "duel" }
    end

    trait :arena do
      battle_type { :arena }
      pvp_mode { "arena" }
    end

    trait :with_low_ap do
      action_points_per_turn { 20 }
    end

    trait :with_high_ap do
      action_points_per_turn { 200 }
    end
  end
end

FactoryBot.define do
  factory :character do
    association :user
    sequence(:name) { |n| "player_#{n}" }
    level { 1 }
    experience { 0 }
    stat_points_available { 0 }
    combat_skill_points { 0 }
    peace_skill_points { 0 }
    perk_points { 0 }
    allocated_stats { {} }
    perks { {} }
    alignment { Character::ALIGNMENTS[:none] }
    fatigue_percent { 0 }

    after(:create) do |character|
      create(:inventory, character:) unless character.inventory
    end

    trait :with_position do
      after(:create) do |character|
        zone = create(:zone)
        create(:character_position, character:, zone:)
      end
    end

    trait :with_new_perk_point do
      perk_points { 1 }
    end

    trait :with_more_strength_perk do
      perks { {"more_strength" => true} }
    end

    trait :without_perk_points do
      perk_points { 0 }
    end
  end
end

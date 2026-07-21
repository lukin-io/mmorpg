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

    trait :resuming_shop do
      metadata do
        {
          Character::GAMEPLAY_CONTEXT_KEY => {
            "name" => "shop",
            "params" => {"mode" => "buy", "category" => "all"}
          }
        }
      end
    end

    trait :with_malformed_gameplay_context do
      metadata { {Character::GAMEPLAY_CONTEXT_KEY => "https://example.invalid"} }
    end

    trait :with_null_gameplay_context do
      metadata { {Character::GAMEPLAY_CONTEXT_KEY => nil} }
    end

    trait :with_malformed_shop_gameplay_context do
      metadata do
        {
          Character::GAMEPLAY_CONTEXT_KEY => {
            "name" => "shop",
            "params" => nil
          }
        }
      end
    end

    trait :resuming_city_building do
      metadata do
        {
          Character::GAMEPLAY_CONTEXT_KEY => {
            "name" => "city_building",
            "params" => {"building_key" => "market"}
          }
        }
      end
    end
  end
end

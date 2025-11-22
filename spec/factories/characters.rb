FactoryBot.define do
  factory :character do
    association :user
    association :character_class
    sequence(:name) { |n| "Hero#{n}" }
    level { 1 }
    experience { 0 }
    stat_points_available { 0 }
    skill_points_available { 0 }
    allocated_stats { {} }
    reputation { 0 }
    faction_alignment { Character::ALIGNMENTS[:neutral] }
    alignment_score { 0 }
    resource_pools { {"stamina" => 100} }

    after(:create) do |character|
      create(:inventory, character:) unless character.inventory
    end

    trait :with_position do
      after(:create) do |character|
        zone = create(:zone)
        create(:character_position, character:, zone:)
      end
    end
  end
end

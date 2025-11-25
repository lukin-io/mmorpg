FactoryBot.define do
  factory :pet_companion do
    association :user
    association :pet_species
    level { 1 }
    bonding_experience { 0 }
    affinity_stage { "neutral" }
    stats { {} }
  end
end

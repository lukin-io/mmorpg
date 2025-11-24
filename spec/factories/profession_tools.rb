FactoryBot.define do
  factory :profession_tool do
    association :character
    profession
    tool_type { "#{profession.name} Kit" }
    quality_rating { 10 }
    durability { 100 }
    max_durability { 100 }
    metadata { {} }
  end
end

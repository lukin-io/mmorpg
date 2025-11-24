FactoryBot.define do
  factory :movement_command do
    association :character
    association :zone
    direction { "north" }
    status { :queued }
    metadata { {} }
  end
end

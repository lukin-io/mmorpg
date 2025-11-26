FactoryBot.define do
  factory :integration_token do
    association :created_by, factory: :user
    name { "fan_tools" }
    scopes { ["fan_tools.read"] }
  end
end

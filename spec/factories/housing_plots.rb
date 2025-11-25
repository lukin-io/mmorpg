FactoryBot.define do
  factory :housing_plot do
    association :user
    location_key { "evergreen_city_#{SecureRandom.hex(2)}" }
    plot_type { "cottage" }
    plot_tier { "starter" }
    exterior_style { "classic" }
    visit_scope { "friends" }
    storage_slots { 20 }
    room_slots { 1 }
    utility_slots { 1 }
    access_rules { {public: false} }

    trait :showcased do
      showcase_enabled { true }
    end
  end
end

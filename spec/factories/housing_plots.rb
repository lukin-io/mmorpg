FactoryBot.define do
  factory :housing_plot do
    association :user
    location_key { "evergreen_city_#{SecureRandom.hex(2)}" }
    plot_type { "cottage" }
    storage_slots { 20 }
    access_rules { {public: false} }
  end
end

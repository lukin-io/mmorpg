# frozen_string_literal: true

FactoryBot.define do
  factory :map_tile_template do
    sequence(:zone) { |n| "Zone #{n}" }
    sequence(:x) { |n| n % 10 }
    sequence(:y) { |n| n / 10 }
    terrain_type { "outdoor" }
    passable { true }
    metadata { {} }
  end
end

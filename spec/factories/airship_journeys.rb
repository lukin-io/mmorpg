FactoryBot.define do
  factory :airship_journey do
    association :character
    association :source_zone, factory: [:zone, :city]
    association :destination_zone, factory: [:zone, :city]
    transient do
      flight_region { association :zone, :mvp_outdoor_region }
    end
    source_x { 0 }
    source_y { 0 }
    destination_x { 0 }
    destination_y { 0 }
    last_position_zone { character.position&.zone || source_zone }
    last_position_x { character.position&.x || source_x }
    last_position_y { character.position&.y || source_y }
    sequence(:route_key) { |number| "flight_#{number}" }
    route_label { "Route Forpost - Oktal" }
    fare_nv { 150 }
    boarded_at { Time.current }
    departs_at { 1.minute.from_now }
    arrives_at { departs_at + 4.minutes }
    boarding_offer do
      association :world_action_offer, character:, zone: source_zone, x: source_x, y: source_y,
        action_type: "board_airship", status: :accepted
    end
    waypoints do
      [
        {"offset_seconds" => 0, "zone_id" => flight_region.id, "x" => 5, "y" => 5},
        {"offset_seconds" => (arrives_at - departs_at).to_i, "zone_id" => flight_region.id, "x" => 9, "y" => 9}
      ]
    end
  end
end

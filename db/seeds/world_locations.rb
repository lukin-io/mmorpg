# frozen_string_literal: true

# ==============================================================================
# Tile Buildings (Enterable structures on map tiles)
# ==============================================================================
puts "Seeding Tile Buildings..."

if defined?(TileBuilding) && defined?(Zone)
  outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
  tile_buildings = []

  if outpost_surroundings
    Game::World::CityCatalog::GATES.each do |gate_key, gate|
      node = Game::World::CityCatalog.node(gate["node_key"])
      destination_zone = Zone.find_by(name: node["zone_name"])
      next unless destination_zone

      tile_buildings << Seeds::WorldContentSupport.gate_building_attributes(
        gate_key:, gate:, city_zone: destination_zone, outdoors: outpost_surroundings
      )
    end

    tile_buildings << {
      zone: outpost_surroundings.name,
      x: 4,
      y: 6,
      building_key: "frontier_village_entrance",
      building_type: "location",
      name: "Frontier Village",
      destination_zone: nil,
      destination_x: nil,
      destination_y: nil,
      icon: nil,
      required_level: 1,
      metadata: {
        "description" => "Enter the village from this world cell.",
        "source_map" => "m_998_998",
        "source_coordinates" => [998, 998],
        "location" => {
          "short_label" => "Village",
          "presence_label" => "Village Square",
          "kind" => "village",
          "scene" => {"width" => 760, "height" => 255},
          "features" => [
            {
              "key" => "trading_post",
              "label" => "Trading Post",
              "presence_label" => "Shop",
              "action_type" => "open_feature",
              "feature" => "shop",
              "polygon" => [
                [237, 194], [205, 196], [141, 177], [86, 154], [85, 146],
                [108, 123], [189, 114], [219, 156], [221, 173], [238, 180]
              ]
            },
            {
              "key" => "exit",
              "label" => "Leave the village",
              "action_type" => "return_world",
              "polygon" => [
                [527, 235], [554, 238], [551, 245], [566, 243], [577, 239],
                [569, 227], [561, 218], [557, 224], [544, 213], [536, 210]
              ]
            }
          ]
        }
      }
    }

    # These captured lobbies share the same cell entry/return contract. Their
    # read-only tabs do not activate underground travel or resource trading.
    [
      {
        x: 4, y: 5, key: "podgorny_mine", name: "Podgorny Mine", kind: "mine",
        presence_label: "Dragon Fang, Mine", source_coordinates: [998, 997],
        image: "world/locations/forpost-mine.png", unavailable_actions: ["Descend"],
        sections: [
          {"key" => "entrance", "label" => "Mine entrance", "summary_label" => "Mine in Podgornaya Village"},
          {"key" => "shop", "label" => "Shop", "read_only_items" => [
            {"name" => "Mining license III", "details" => ["600 NV", "Duration: 10 days"]},
            {"name" => "Mining license II", "details" => ["350 NV", "Duration: 6 days"]},
            {"name" => "Mining license I", "details" => ["200 NV", "Duration: 3 days"]},
            {"name" => "Sturdy helmet", "details" => ["50 NV", "Durability: 70/70", "Mass: 7"]},
            {"name" => "Simple helmet", "details" => ["40 NV", "Durability: 60/60", "Mass: 5"]}
          ]}
        ]
      },
      {
        x: 4, y: 7, key: "forpost_resource_exchange", name: "Resource Exchange", kind: "exchange",
        presence_label: "Outpost, Exchange", source_coordinates: [998, 999],
        image: "world/locations/forpost-exchange.png", unavailable_actions: ["Processing Point"],
        sections: [
          {"key" => "sell", "label" => "Sell resources"},
          {"key" => "buy", "label" => "Buy resources"},
          {"key" => "storage", "label" => "Storage"}
        ],
        resource_categories: [
          "Fish resources", "Fish components", "Cooking resources", "Plant resources",
          "Alchemy components", "Hunting resources", "Hunting alchemy components", "Mineral resources",
          "Wood", "Wooden blanks", "Firewood", "Alloys and metals"
        ]
      }
    ].each do |lobby|
      source_x, source_y = lobby.fetch(:source_coordinates)
      tile_buildings << {
        zone: outpost_surroundings.name, x: lobby.fetch(:x), y: lobby.fetch(:y),
        building_key: lobby.fetch(:key), building_type: "location", name: lobby.fetch(:name), required_level: 0,
        metadata: {
          "presence_label" => lobby.fetch(:presence_label),
          "source_map" => "m_#{source_x}_#{source_y}",
          "source_coordinates" => lobby.fetch(:source_coordinates),
          "location" => {
            "kind" => lobby.fetch(:kind), "presence_label" => lobby.fetch(:name),
            "scene" => {"width" => 760, "height" => 255, "image" => lobby.fetch(:image)},
            "sections" => lobby.fetch(:sections),
            "resource_categories" => lobby.fetch(:resource_categories, []),
            "unavailable_actions" => lobby.fetch(:unavailable_actions),
            "features" => [{"key" => "exit", "label" => "Nature", "action_type" => "return_world", "placement" => "navigation"}]
          }
        }
      }
    end
  end

  tile_buildings.each do |attrs|
    building = TileBuilding.find_or_initialize_by(building_key: attrs[:building_key])
    if attrs[:building_type] == "location"
      # Linked locations are editable after bootstrap, including records from
      # before this preservation policy. Keep their stable key, moves, disabled
      # state and existing offers; do not take over an independently owned cell.
      # The explicit CityCatalog gates below still reconcile both handoff ends.
      next if building.persisted? || TileBuilding.exists?(zone: attrs[:zone], x: attrs[:x], y: attrs[:y])
    end
    building.assign_attributes(
      zone: attrs[:zone],
      x: attrs[:x],
      y: attrs[:y],
      building_type: attrs[:building_type],
      name: attrs[:name],
      destination_zone: attrs[:destination_zone],
      destination_x: attrs[:destination_x],
      destination_y: attrs[:destination_y],
      icon: attrs[:icon],
      required_level: attrs[:required_level],
      active: true,
      metadata: attrs[:metadata] || {}
    )
    ApplicationRecord.transaction do
      Seeds::WorldContentSupport.cancel_changed_action_offers(building)
      building.save!
    end
    puts "  Created/Found TileBuilding: #{attrs[:name]}"
  end


  current_city_gate_keys = tile_buildings.pluck(:building_key)
  retired_city_gates = TileBuilding
    .where(building_key: %w[outpost_gate outpost_south_gate outpost_east_gate])
    .where.not(building_key: current_city_gate_keys)
  ApplicationRecord.transaction do
    Seeds::WorldContentSupport.retire_action_targets("TileBuilding", retired_city_gates)
    retired_city_gates.destroy_all
  end
end

puts "Tile buildings seeding complete!"

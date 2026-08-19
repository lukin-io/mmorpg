# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open-world seed data", type: :model do
  def load_seed
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
  end

  it "upgrades stale starter data and remains idempotent" do
    city = create(:zone, :city, name: "Outpost", width: 5, height: 5, metadata: {"stale" => true})
    region = create(
      :zone,
      name: "Outpost Surroundings",
      location_type: "outdoor",
      width: 15,
      height: 15,
      metadata: {"stale" => true}
    )
    tile = create(
      :map_tile_template,
      zone: region.name,
      x: 7,
      y: 7,
      metadata: {"stale" => true}
    )
    gate = create(
      :tile_building,
      zone: region.name,
      x: 1,
      y: 1,
      building_key: "outpost_gate",
      destination_zone: nil,
      metadata: {"stale" => true}
    )
    legacy_south_gate_id = MapTileTemplate.insert_all!([
      {
        zone: city.name,
        x: 5,
        y: 9,
        terrain_type: "city",
        passable: true,
        metadata: {"building" => "South Gate"},
        created_at: Time.current,
        updated_at: Time.current
      }
    ]).rows.first.first
    legacy_town_hotspot = create(
      :city_hotspot,
      zone: city,
      key: "generic_town_hall",
      name: "Generic Town Hall"
    )
    create(:spawn_point, zone: city, x: 5, y: 5, default_entry: true)
    create(:spawn_point, zone: region, x: 7, y: 7, default_entry: true)
    stale_seeded_npc = create(
      :tile_npc,
      zone: region.name,
      x: 50,
      y: 50,
      metadata: {"seed_source" => "outdoor_npcs.yml"}
    )
    stale_plague_rat_template = create(
      :npc_template,
      npc_key: "plague_rat",
      name: "Stale Plague Rat",
      metadata: {"obsolete" => true}
    )
    create(
      :tile_npc,
      zone: region.name,
      x: 7,
      y: 7,
      npc_template: stale_plague_rat_template,
      npc_key: "plague_rat",
      current_hp: 55,
      max_hp: 60,
      metadata: {"seed_source" => "outdoor_npcs.yml", "obsolete" => true}
    )

    load_seed

    expect(region.reload).to have_attributes(
      location_type: "outdoor",
      width: 1000,
      height: 1000,
      metadata: {"source_map" => "m_1001_999"}
    )
    expect(city.reload).to have_attributes(width: 10, height: 10)
    expect(city.metadata).to include(
      "city_key" => "forpost",
      "city_node_key" => "main",
      "title" => "Central Square"
    )
    expect(city.city_presentation).to include(
      "image_offset" => [-143, -212],
      "focus" => [625, 300]
    )
    expect(MapTileTemplate.exists?(legacy_south_gate_id)).to be false
    expect(MapTileTemplate.where(zone: city.name)).to be_empty
    expect(CityHotspot.exists?(legacy_town_hotspot.id)).to be false
    expect(TileNpc.exists?(stale_seeded_npc.id)).to be false
    expect(tile.reload).to have_attributes(terrain_type: "outdoor", passable: true)
    expect(tile.local_action("resource_search")).to include("source_id" => "look")
    expect(tile.cell_art).to eq(
      "key" => "forpost_terrain",
      "column" => 7,
      "row" => 7
    )
    expect(gate.reload).to have_attributes(
      zone: region.name,
      x: 7,
      y: 0,
      destination_zone: city,
      destination_x: 0,
      destination_y: 0,
      icon: nil,
      active: true
    )
    expect(gate.metadata).to include(
      "source_map" => "m_1019_1025",
      "source_coordinates" => [1019, 1025],
      "source_gate" => "west"
    )

    node_zones = Game::World::CityCatalog::NODES.transform_values do |node|
      Zone.find_by!(name: node["zone_name"])
    end
    expect(node_zones.size).to eq(5)
    expect(node_zones.transform_values(&:city_node_key)).to eq(
      Game::World::CityCatalog::NODES.keys.index_with(&:itself)
    )
    expect(SpawnPoint.where(zone: node_zones.values).pluck(:zone_id, :x, :y, :default_entry)).to eq(
      [[node_zones.fetch("main").id, 0, 0, true]]
    )
    expect(SpawnPoint.where(zone: region)).to be_empty

    seeded_gates = TileBuilding.where(
      building_key: ["outpost_gate", "outpost_south_gate", "outpost_east_gate"]
    ).index_by { |building| building.metadata["source_gate"] }
    expect(seeded_gates.keys).to contain_exactly("west")
    Game::World::CityCatalog::GATES.each do |gate_key, gate_definition|
      seeded_gate = seeded_gates.fetch(gate_key)
      expected_node = node_zones.fetch(gate_definition["node_key"])
      expect(seeded_gate.destination_zone).to eq(expected_node)
      expect([seeded_gate.x, seeded_gate.y]).to eq(gate_definition["local_coordinates"])
      expect(seeded_gate.metadata["source_coordinates"]).to eq(gate_definition["source_coordinates"])
      seeded_tile = MapTileTemplate.find_by!(
        zone: region.name,
        x: seeded_gate.x,
        y: seeded_gate.y
      )
      expect(seeded_tile.cell_art).to eq(
        "key" => "forpost_terrain",
        "column" => seeded_gate.x.modulo(10),
        "row" => seeded_gate.y.modulo(10)
      )
      expect(seeded_tile.cell_art_presentation).to have_attributes(
        key: "forpost_terrain",
        cell_width: 100,
        cell_height: 100
      )
    end

    village = TileBuilding.find_by!(building_key: "frontier_village_entrance")
    expect(village).to have_attributes(
      zone: region.name,
      x: 4,
      y: 6,
      building_type: "location",
      destination_zone: nil,
      destination_x: nil,
      destination_y: nil,
      active: true
    )
    expect(village.metadata).to include(
      "source_map" => "m_998_998",
      "source_coordinates" => [998, 998],
      "landmark_kind" => "village"
    )
    expect(village.location_key).to eq("frontier_village_entrance")
    expect(village.location_scene_size).to eq([760, 255])
    expect(village.location_features.pluck("key", "action_type", "feature")).to contain_exactly(
      ["trading_post", "open_feature", "shop"],
      ["exit", "return_world", nil]
    )
    expect(village.location_feature("trading_post").fetch("polygon")).to eq(
      [
        [237, 194], [205, 196], [141, 177], [86, 154], [85, 146],
        [108, 123], [189, 114], [219, 156], [221, 173], [238, 180]
      ]
    )

    expect(CityHotspot.active.where(zone: node_zones.values).count).to eq(14)
    expect(
      CityHotspot.active.where(zone: node_zones.values).where.not(key: "arena").distinct.pluck(:required_level)
    ).to eq([0])
    expect(
      CityHotspot.active.find_by!(zone: node_zones.fetch("main"), key: "arena").required_level
    ).to eq(0)
    expect(CityHotspot.active.find_by!(zone: node_zones.fetch("main"), key: "shop")).to have_attributes(
      position_x: 96,
      position_y: 303,
      width: 320,
      height: 182
    )
    expect(CityHotspot.active.find_by!(zone: node_zones.fetch("main"), key: "go_forpost3")).to have_attributes(
      presentation_direction: "southwest"
    )

    plague_rat = TileNpc.find_by!(zone: region.name, x: 7, y: 7)
    expect(plague_rat).to have_attributes(npc_key: "plague_rat", level: 4, current_hp: 55, max_hp: 100)
    expect(plague_rat.metadata).to include(
      "seed_source" => "outdoor_npcs.yml",
      "encounter_count" => 2
    )
    expect(plague_rat.metadata).not_to have_key("obsolete")
    expect(plague_rat.npc_template.metadata).to include(
      "health" => 100,
      "base_damage" => 7,
      "seed_source" => "outdoor_npcs.yml"
    )
    expect(plague_rat.npc_template.metadata).not_to have_key("obsolete")

    expect {
      load_seed
    }.not_to change {
      [
        Zone.where(name: [city.name, region.name] + node_zones.values.map(&:name)).count,
        MapTileTemplate.where(zone: region.name).count,
        TileBuilding.where(
          building_key: seeded_gates.values.map(&:building_key) + [village.building_key]
        ).count,
        CityHotspot.active.where(zone: node_zones.values).count,
        TileNpc.where("metadata ->> 'seed_source' = ?", "outdoor_npcs.yml").count,
        SpawnPoint.where(zone: node_zones.values).count
      ]
    }
  end

  it "retires the historical city graph without stranding characters or live actions" do
    central = create(
      :zone,
      :city,
      name: "Outpost",
      metadata: {"city_key" => "forpost", "city_node_key" => "city2_1"}
    )
    knowledge = create(
      :zone,
      :city,
      name: "Outpost Knowledge Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "city2_6"}
    )
    retired_stables = create(
      :zone,
      :city,
      name: "Outpost Stables",
      metadata: {"city_key" => "forpost", "city_node_key" => "city2_7"}
    )
    outdoors = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings")
    retained_position = create(:character_position, zone: knowledge, x: 4, y: 4)
    retired_position = create(:character_position, zone: retired_stables, x: 3, y: 2)
    create(:spawn_point, zone: retired_stables, x: 0, y: 0)
    retired_tile = create(:map_tile_template, zone: retired_stables.name, x: 0, y: 0)
    stale_central_route = create(
      :city_hotspot,
      :district,
      zone: central,
      destination_zone: retired_stables,
      key: "go_city2_7"
    )
    stale_exit = create(
      :city_hotspot,
      :city_gate,
      zone: retired_stables,
      destination_zone: outdoors,
      key: "south_gate",
      action_params: {"destination_x" => 10, "destination_y" => 3}
    )
    stale_offer = create(
      :world_action_offer,
      character: retired_position.character,
      zone: retired_stables,
      x: retired_position.x,
      y: retired_position.y,
      action_type: "exit_city",
      target: stale_exit
    )
    stale_gate = create(
      :tile_building,
      zone: outdoors.name,
      x: 10,
      y: 3,
      building_key: "outpost_south_gate",
      destination_zone: retired_stables
    )
    outdoor_position = create(:character_position, zone: outdoors, x: 10, y: 3)
    stale_gate_offer = create(
      :world_action_offer,
      character: outdoor_position.character,
      zone: outdoors,
      x: outdoor_position.x,
      y: outdoor_position.y,
      action_type: "enter_building",
      target: stale_gate
    )

    load_seed

    canonical_central = Zone.find_by!(name: "Outpost")
    expect(knowledge.reload.city_node_key).to eq("forpost2")
    expect(retained_position.reload).to have_attributes(zone: knowledge, x: 4, y: 4)
    expect(retired_position.reload).to have_attributes(zone: canonical_central, x: 0, y: 0)
    expect(SpawnPoint.where(zone: retired_stables)).to be_empty
    expect(MapTileTemplate.exists?(retired_tile.id)).to be false
    expect(CityHotspot.where(id: [stale_central_route.id, stale_exit.id])).to be_empty
    expect(stale_offer.reload).to be_cancelled
    expect(stale_offer.target).to be_nil
    expect(stale_gate_offer.reload).to be_cancelled
    expect(stale_gate_offer.target).to be_nil
    expect(TileBuilding.where(building_key: "outpost_south_gate")).to be_empty
    expect(CityHotspot.active.where(hotspot_type: "exit").pluck(:key)).to eq(["west_gate"])

    expect {
      load_seed
    }.not_to change {
      [
        retained_position.reload.attributes.slice("zone_id", "x", "y"),
        retired_position.reload.attributes.slice("zone_id", "x", "y"),
        CityHotspot.active.where(zone: Game::World::CityCatalog::NODES.values.filter_map { |node|
          Zone.find_by(name: node["zone_name"])
        }).count,
        TileBuilding.where(building_key: %w[outpost_gate outpost_south_gate outpost_east_gate]).count
      ]
    }
  end
end

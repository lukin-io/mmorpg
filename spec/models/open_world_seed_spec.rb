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
      "city_node_key" => "city2_1",
      "title" => "Central Square"
    )
    expect(MapTileTemplate.exists?(legacy_south_gate_id)).to be false
    expect(MapTileTemplate.where(zone: city.name)).to be_empty
    expect(CityHotspot.exists?(legacy_town_hotspot.id)).to be false
    expect(tile.reload).to have_attributes(terrain_type: "outdoor", passable: true)
    expect(tile.local_action("resource_search")).to include("source_id" => "look")
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
    expect(node_zones.size).to eq(9)
    expect(node_zones.transform_values(&:city_node_key)).to eq(
      Game::World::CityCatalog::NODES.keys.index_with(&:itself)
    )
    expect(SpawnPoint.where(zone: node_zones.values).pluck(:zone_id, :x, :y, :default_entry)).to eq(
      [[node_zones.fetch("city2_1").id, 0, 0, true]]
    )
    expect(SpawnPoint.where(zone: region)).to be_empty

    seeded_gates = TileBuilding.where(
      building_key: ["outpost_gate", "outpost_south_gate", "outpost_east_gate"]
    ).index_by { |building| building.metadata["source_gate"] }
    expect(seeded_gates.keys).to contain_exactly("west", "south", "east")
    Game::World::CityCatalog::GATES.each do |gate_key, gate_definition|
      seeded_gate = seeded_gates.fetch(gate_key)
      expected_node = node_zones.fetch(gate_definition["node_key"])
      expect(seeded_gate.destination_zone).to eq(expected_node)
      expect([seeded_gate.x, seeded_gate.y]).to eq(gate_definition["local_coordinates"])
      expect(seeded_gate.metadata["source_coordinates"]).to eq(gate_definition["source_coordinates"])
    end

    expect(CityHotspot.active.where(zone: node_zones.values).count).to eq(32)

    expect {
      load_seed
    }.not_to change {
      [
        Zone.where(name: [city.name, region.name] + node_zones.values.map(&:name)).count,
        MapTileTemplate.where(zone: region.name).count,
        TileBuilding.where(building_key: seeded_gates.values.map(&:building_key)).count,
        CityHotspot.active.where(zone: node_zones.values).count,
        SpawnPoint.where(zone: node_zones.values).count
      ]
    }
  end
end

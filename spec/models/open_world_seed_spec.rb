# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open-world seed data", type: :model do
  def load_seed
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
  end

  it "imports the bounded survey, keeps NPC pools distinct, and preserves managed cells on retry" do
    region = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings")
    legacy = create(:map_tile_template, zone: region.name, x: 14, y: 10, passable: true,
      metadata: {"source_map" => "forpost_pond_neighborhood_art"})
    position = create(:character_position, zone: region, x: 14, y: 10)

    load_seed

    catalog = Game::World::StarterCellCatalog.default
    imported = MapTileTemplate.where(zone: region.name, x: 0..20, y: 2..14).to_a
    expect(imported.size).to eq(273)
    expect(imported.count(&:passable)).to eq(118)
    imported.each do |tile|
      source = catalog.at(tile.x, tile.y)
      expect(tile.metadata.fetch("atlas")).to eq(source.metadata.fetch("atlas"))
      expect(tile.passable).to eq(source.passable)
    end
    expect(legacy.reload).not_to be_passable
    expect(position.reload).to have_attributes(zone: region, x: 14, y: 10)
    pond = imported.find { |tile| [tile.x, tile.y] == [13, 10] }
    expect(pond.resource_groups).to eq([
      {"key" => "herbs_2", "kind" => "herbs", "label" => "Herb group 2", "active" => true}
    ])
    expect(pond.metadata.dig("atlas", "npc_annotations")).to eq([])
    rat = imported.find { |tile| [tile.x, tile.y] == [7, 7] }
    expect(rat.metadata.dig("atlas", "npc_annotations")).to include(
      "name" => "Крысы", "min_level" => 0, "max_level" => 4
    )
    placements = TileNpc.where(zone: region.name)
    expect(placements.where("metadata ->> 'seed_scope' IS NULL").pluck(:x, :y))
      .to contain_exactly([7, 7], [14, 15])
    expect(placements.where("metadata ->> 'seed_scope' = ?", "starter_encounter_bootstrap").count).to eq(40)

    managed = MapTileTemplate.find_by!(zone: region.name, x: 12, y: 10)
    managed.update!(passable: false, metadata: managed.metadata.merge("resource_groups" => []))
    original = managed.attributes
    load_seed
    expect(managed.reload.attributes).to eq(original)
  end

  it "authors the observed pond in the existing outdoor zone with drinking and the empty fishing entry" do
    load_seed
    zone = Zone.find_by!(name: "Outpost Surroundings")
    pond = MapTileTemplate.find_by!(zone: zone.name, x: 13, y: 10)

    expect(Zone.where(location_type: "outdoor").count).to eq(1)
    expect(pond).to be_passable
    expect(pond.metadata).to include("source_coordinates" => [1007, 1002])
    expect(pond.cell_art_presentation).to have_attributes(
      asset: "world/cells/forpost-starter/13_8.png", column: 13, row: 8,
      sheet_width: 100, sheet_height: 100
    )
    expect(pond.active_local_actions.pluck("type")).to match_array(%w[resource_search drinking fishing])
    expect(pond.local_action("resource_search")).to include("result_message" => "Nothing found.")
    expect(MapTileTemplate.local_action_implemented?("drinking")).to be true
    expect(MapTileTemplate.local_action_implemented?("fishing")).to be true
    expect { load_seed }.not_to change(MapTileTemplate, :count)
  end

  it "keeps pond artwork independent from surveyed cell availability and actions" do
    load_seed
    cells = MapTileTemplate.where(zone: "Outpost Surroundings", x: 11..15, y: 8..12).order(:y, :x).to_a

    expect(cells.size).to eq(25)
    cells.each do |cell|
      column = cell.x
      row = cell.y - 2
      expect(cell.cell_art).to eq("key" => "forpost_starter", "column" => column, "row" => row)
      expect(cell.cell_art_presentation).to have_attributes(
        asset: "world/cells/forpost-starter/#{column}_#{row}.png", background_x: 0, background_y: 0,
        cell_width: 100, cell_height: 100, sheet_width: 100, sheet_height: 100
      )
      next if [cell.x, cell.y] == [13, 10]

      expected_actions = [cell.x, cell.y] == [12, 10] ? ["resource_search"] : []
      expect(cell.active_local_actions.pluck("type")).to eq(expected_actions)
      surveyed = Game::World::StarterCellCatalog.default.at(cell.x, cell.y)
      expect(cell.passable).to eq(surveyed.passable)
      expect(cell.metadata["source_coordinates"]).to eq([cell.x + 994, cell.y + 992])
    end
    expect(TileNpc.where(zone: "Outpost Surroundings", x: 13, y: 10)).to be_empty
    expect(TileBuilding.where(zone: "Outpost Surroundings", x: 11..15, y: 8..12).pluck(:building_key)).to eq(["outpost_east_gate"])
  end

  it "preserves gameplay layers and saved state while reconciling the neighborhood artwork" do
    load_seed
    region = Zone.find_by!(name: "Outpost Surroundings")
    center = MapTileTemplate.find_by!(zone: region.name, x: 13, y: 10)
    center.update!(passable: false, metadata: center.metadata.merge("managed_note" => "Retain pond override"))
    neighbor = MapTileTemplate.find_by!(zone: region.name, x: 12, y: 10)
    neighbor.update!(passable: false, metadata: {
      "source_map" => "authored_neighbor",
      "resource_groups" => [{"key" => "herbs_review", "kind" => "herbs", "label" => "Review group", "active" => false}],
      "local_actions" => [{"type" => "digging", "source_id" => "dig", "active" => false}],
      "cell_art" => {"key" => "forpost_terrain", "column" => 2, "row" => 0}
    })
    npc = create(:tile_npc, zone: region.name, x: 12, y: 10, current_hp: 15, metadata: {"active" => false})
    entrance = create(:tile_building, :world_location, :inactive, zone: region.name, x: 12, y: 10)
    position = create(:character_position, zone: region, x: 13, y: 10)
    original_npc = npc.attributes
    original_entrance = entrance.attributes
    original_metadata = neighbor.metadata.except("cell_art")
    original_center = center.metadata.except("cell_art")

    expect { load_seed }.not_to change(MapTileTemplate, :count)

    expect(neighbor.reload).not_to be_passable
    expect(neighbor.metadata.except("cell_art")).to eq(original_metadata)
    expect(neighbor.cell_art).to eq("key" => "forpost_starter", "column" => 12, "row" => 8)
    expect(center.reload).not_to be_passable
    expect(center.metadata.except("cell_art")).to eq(original_center)
    expect(npc.reload.attributes).to eq(original_npc)
    expect(entrance.reload.attributes).to eq(original_entrance)
    expect(position.reload).to have_attributes(zone: region, x: 13, y: 10)
    expect { load_seed }.not_to change { neighbor.reload.updated_at }
  end

  it "reproduces the observed Forpost gate, village route, and resource-cell neighbors" do
    load_seed
    region = Zone.find_by!(name: "Outpost Surroundings")
    expect(Zone.where(location_type: "outdoor").pluck(:id)).to eq([region.id])
    character = create(:character)
    position = create(:character_position, character:, zone: region, x: 6, y: 8)
    observed_destinations = {
      [6, 8] => [[5, 7], [6, 7], [7, 7], [5, 8], [5, 9]],
      [5, 7] => [[4, 6], [4, 7], [6, 7], [5, 8], [6, 8]],
      [4, 6] => [[3, 5], [4, 5], [3, 6], [3, 7], [4, 7], [5, 7]],
      [6, 7] => [[7, 6], [5, 7], [7, 7], [5, 8], [6, 8]],
      [7, 7] => [[7, 6], [8, 6], [6, 7], [8, 7], [6, 8]],
      [11, 9] => [[11, 10], [12, 10]],
      [12, 10] => [[11, 9], [11, 10], [13, 10], [11, 11], [12, 11], [13, 11]],
      [13, 10] => [[14, 9], [12, 10], [12, 11], [13, 11], [14, 11]]
    }

    observed_destinations.each do |(x, y), destinations|
      position.update!(x:, y:)
      state = Game::Movement::MapState.new(character:).call
      expect(state.destinations.map { |offer| [offer.target_x, offer.target_y] })
        .to match_array(destinations), "unexpected destinations from #{[x, y]}"
    end

    expect(TileBuilding.find_by!(building_key: "frontier_village_entrance"))
      .to have_attributes(x: 4, y: 6)
    gate_exit = CityHotspot.find_by!(key: "west_gate", zone: Zone.find_by!(name: "Outpost"))
    expect(gate_exit.action_params).to include("destination_x" => 6, "destination_y" => 8)
  end

  it "retires an obsolete gate inside the survey without deleting its blocked cell" do
    region = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings")
    art = {"key" => "forpost_terrain", "column" => 2, "row" => 0}
    old_tile = create(:map_tile_template, zone: region.name, x: 10, y: 9, passable: true,
      metadata: {"city_gate" => "Retired Gate", "source_map" => "m_1019_1025",
                 "cell_art" => art, "managed_note" => "Retain existing content"})
    position = create(:character_position, zone: region, x: 10, y: 9)

    load_seed

    expect(MapTileTemplate.exists?(old_tile.id)).to be(true)
    expect(old_tile.reload).not_to be_passable
    expect(old_tile.metadata).not_to have_key("city_gate")
    expect(old_tile.metadata).to include("source_map" => "m_1004_1001", "source_coordinates" => [1004, 1001],
      "cell_art" => {"key" => "forpost_starter", "column" => 10, "row" => 7}, "managed_note" => "Retain existing content")
    expect(old_tile.metadata.fetch("atlas")).to eq(Game::World::StarterCellCatalog.default.at(10, 9).metadata.fetch("atlas"))
    expect(MapTileTemplate.where(zone: region.name, x: 0..20, y: 2..14).count).to eq(273)
    expect(position.reload).to have_attributes(zone: region, x: 10, y: 9)

    original = old_tile.attributes
    expect { load_seed }.not_to change(MapTileTemplate, :count)
    expect(old_tile.reload.attributes).to eq(original)
  end

  it "retires the old gate cell without relocating a saved outdoor player" do
    region = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings")
    old_tile = create(:map_tile_template, zone: region.name, x: 7, y: 0,
      metadata: {"city_gate" => "City Exit", "source_map" => "m_1019_1025"})
    position = create(:character_position, zone: region, x: 7, y: 0)

    load_seed

    expect(MapTileTemplate.exists?(old_tile.id)).to be false
    expect(position.reload).to have_attributes(zone: region, x: 7, y: 0)
    expect(TileBuilding.find_by!(building_key: "outpost_gate")).to have_attributes(x: 6, y: 8)
    expect { load_seed }.not_to change { MapTileTemplate.count }
    expect(position.reload).to have_attributes(zone: region, x: 7, y: 0)
  end

  it "cancels only live offers for changed seeded entrances and preserves a no-op reseed" do
    load_seed
    region = Zone.find_by!(name: "Outpost Surroundings")
    city = Zone.find_by!(name: "Outpost")
    character = create(:character)
    position = create(:character_position, character:, zone: region, x: 7, y: 0)
    gate = TileBuilding.find_by!(building_key: "outpost_gate")
    exit_hotspot = CityHotspot.find_by!(zone: city, key: "west_gate")
    gate.update!(x: 7, y: 0)
    exit_hotspot.update!(action_params: exit_hotspot.action_params.merge("destination_x" => 7, "destination_y" => 0))
    entry_offer = create(:world_action_offer, character:, zone: region, x: 7, y: 0,
      target: gate, action_type: "enter_building")
    exit_offer = create(:world_action_offer, :accepted, character:, zone: city, x: 0, y: 0,
      target: exit_hotspot, action_type: "exit_city")
    history = create(:world_action_offer, :completed, character:, zone: region, x: 7, y: 0,
      target: gate, action_type: "enter_building")
    village = TileBuilding.find_by!(building_key: "frontier_village_entrance")
    unaffected_offer = create(:world_action_offer, character:, zone: region, x: 4, y: 6,
      target: village, action_type: "enter_building")

    load_seed

    expect(entry_offer.reload).to be_cancelled
    expect(entry_offer.target).to eq(gate)
    expect(exit_offer.reload).to be_cancelled
    expect(exit_offer.target).to eq(exit_hotspot)
    expect(history.reload).to be_completed
    expect(history.target).to eq(gate)
    expect(unaffected_offer.reload).to be_offered
    expect(position.reload).to have_attributes(zone: region, x: 7, y: 0)

    fresh_offer = create(:world_action_offer, character:, zone: city, x: 0, y: 0,
      target: exit_hotspot, action_type: "exit_city")
    load_seed

    expect(fresh_offer.reload).to be_offered
    expect(unaffected_offer.reload).to be_offered
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
      "key" => "forpost_starter",
      "column" => 7,
      "row" => 5
    )
    expect(gate.reload).to have_attributes(
      zone: region.name,
      x: 6,
      y: 8,
      destination_zone: city,
      destination_x: 0,
      destination_y: 0,
      icon: nil,
      active: true
    )
    expect(gate.metadata).to include(
      "source_map" => "m_1000_1000",
      "source_coordinates" => [1000, 1000],
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
    expect(seeded_gates.keys).to contain_exactly("west", "east")
    Game::World::CityCatalog::GATES.each do |gate_key, gate_definition|
      seeded_gate = seeded_gates.fetch(gate_key)
      expected_node = node_zones.fetch(gate_definition["node_key"])
      expect(seeded_gate.destination_zone).to eq(expected_node)
      expect([seeded_gate.x, seeded_gate.y]).to eq(gate_definition["local_coordinates"])
      expect(seeded_gate.metadata["source_coordinates"]).to eq(gate_definition["source_coordinates"])
      expect(seeded_gate.presence_label).to eq(gate_definition.fetch("presence_label"))
      seeded_tile = MapTileTemplate.find_by!(
        zone: region.name,
        x: seeded_gate.x,
        y: seeded_gate.y
      )
      expected_art = {"key" => "forpost_starter", "column" => seeded_gate.x, "row" => seeded_gate.y - 2}
      expect(seeded_tile.cell_art).to eq(expected_art)
      expect(seeded_tile.cell_art_presentation).to have_attributes(
        key: expected_art.fetch("key"),
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
      "source_coordinates" => [998, 998]
    )
    expect(village.metadata).not_to have_key("landmark_kind")
    expect(village.location_kind).to eq("village")
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

    expect(CityHotspot.active.where(zone: node_zones.values).count).to eq(15)
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

    bandit = TileNpc.find_by!(zone: region.name, x: 14, y: 15)
    expect(bandit).to have_attributes(npc_key: "wilderness_bandit", level: 7, max_hp: 155)
    expect(bandit.metadata).to include(
      "seed_source" => "outdoor_npcs.yml",
      "source_map" => "m_1008_1007",
      "encounter_selection_mode" => "observed_sample_replay"
    )
    expect(bandit.encounter_roster_samples.map { |sample| sample["members"].size }).to eq([3, 1, 1, 2])
    expect(bandit.passive_delay_windows).to eq(
      [
        {"key" => "2026-09-01-interval-1", "min_seconds" => 230, "max_seconds" => 278},
        {"key" => "2026-09-01-interval-2", "min_seconds" => 127, "max_seconds" => 187}
      ]
    )
    expect(NpcTemplate.find_by!(npc_key: "wilderness_robber")).to have_attributes(
      name: "Robber",
      level: 8
    )

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
    expect(CityHotspot.active.where(hotspot_type: "exit").pluck(:key)).to contain_exactly("west_gate", "east_gate")

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

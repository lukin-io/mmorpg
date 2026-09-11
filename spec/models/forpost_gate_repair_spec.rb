# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/forpost_gate_repair")

RSpec.describe Seeds::ForpostGateRepair, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let!(:outdoors) do
    create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings", metadata: {"source_map" => "m_1001_999"})
  end
  let!(:central) do
    create(:zone, :city_node, name: "Outpost")
  end
  let!(:law) do
    create(:zone, :city, name: "Outpost Law Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost4", "title" => "Law Quarter"})
  end

  after { travel_back }

  def repair
    described_class.new.call
  end

  def gate_rows
    [CityHotspot.order(:id).map(&:attributes), TileBuilding.order(:id).map(&:attributes),
      MapTileTemplate.order(:id).map(&:attributes)]
  end

  it "restores Law's exit, the reciprocal entrance and the captured eastern walking route without full seeds" do
    expect { repair }.to change(CityHotspot, :count).by(2).and change(TileBuilding, :count).by(2)
    expect(MapTileTemplate.count).to eq(26)
    character = create(:character)
    position = create(:character_position, character:, zone: law, x: 0, y: 0)
    exit = CityHotspot.find_by!(zone: law, key: "east_gate")
    result = Game::World::CityHotspotService.new(character:, zone: law).interact!(exit.id)
    expect(result.success).to be(true)
    expect(position.reload).to have_attributes(zone: outdoors, x: 11, y: 9)
    entrance = TileBuilding.find_by!(building_key: "outpost_east_gate")
    expect(entrance).to have_attributes(x: 11, y: 9, destination_zone: law, destination_x: 0, destination_y: 0)

    destinations = {
      [11, 9] => [[11, 10], [12, 10]],
      [12, 10] => [[11, 9], [11, 10], [13, 10], [11, 11], [12, 11], [13, 11]],
      [13, 10] => [[14, 9], [12, 10], [12, 11], [13, 11], [14, 11]]
    }
    travel_to(Time.current.change(usec: 0))
    [[12, 10], [13, 10], [12, 10], [11, 9]].each do |target|
      state = Game::Movement::MapState.new(character:).call
      current = [position.reload.x, position.y]
      expect(state.destinations.map { |offer| [offer.target_x, offer.target_y] }).to match_array(destinations.fetch(current))
      offer = state.destinations.find { |item| [item.target_x, item.target_y] == target }
      command = Game::Movement::AcceptMove.new(character:, action_key: offer.action_key).call.command
      travel_to(command.ends_at)
      Game::Movement::CompleteMove.new(character:).call
      expect(position.reload).to have_attributes(x: target.first, y: target.last)
    end

    expect(entrance.enter!(character)).to be(true)
    expect(position.reload).to have_attributes(zone: law, x: 0, y: 0)
    expect(MapTileTemplate.find_by!(zone: outdoors.name, x: 12, y: 10).active_local_actions.pluck("type"))
      .to eq(["resource_search"])
    pond = MapTileTemplate.find_by!(zone: outdoors.name, x: 13, y: 10)
    expect(pond.active_local_actions.pluck("type")).to contain_exactly("resource_search", "drinking", "fishing")
    expect(pond.cell_art).to eq("key" => "forpost_starter", "column" => 13, "row" => 8)
  end

  it "moves the stale west pair once, cancels its capabilities and preserves unrelated content and player state" do
    character = create(:character)
    position = create(:character_position, character:, zone: central, x: 0, y: 0)
    wallet = character.user.currency_wallet
    wallet.update!(nv_balance: 19)
    item = create(:inventory_item, inventory: character.inventory || create(:inventory, character:))
    exit = create(:city_hotspot, :city_gate, zone: central, destination_zone: outdoors, key: "west_gate",
      action_params: {"destination_x" => 7, "destination_y" => 0, "managed_note" => "Keep"})
    entrance = create(:tile_building, zone: outdoors.name, building_key: "outpost_gate", x: 7, y: 0,
      destination_zone: central, metadata: {"source_gate" => "west", "managed_note" => "Keep"})
    old_cell = create(:map_tile_template, zone: outdoors.name, x: 7, y: 0,
      metadata: {"city_gate" => "City Exit", "managed_note" => "Keep"})
    unrelated = create(:map_tile_template, zone: outdoors.name, x: 40, y: 40, metadata: {"source_map" => "managed"})
    unrelated_action = create(:city_hotspot, :shop, zone: central)
    offers = [exit, entrance].map do |target|
      create(:world_action_offer, character:, zone: outdoors, target:)
    end
    historical = create(:world_action_offer, :completed, character:, zone: outdoors, target: entrance)
    kept = [position, wallet, item, item.inventory, character, unrelated, unrelated_action, historical]
    before = kept.map { |record| record.reload.attributes }

    expect(repair).to include(city_exits: 2, outdoor_entrances: 2, retired_markers: 1)
    expect(kept.map { |record| record.reload.attributes }).to eq(before)
    expect(exit.reload.action_params).to include("destination_x" => 6, "destination_y" => 8, "managed_note" => "Keep")
    expect(entrance.reload).to have_attributes(x: 6, y: 8, destination_zone: central)
    expect(entrance.metadata).to include("managed_note" => "Keep", "source_coordinates" => [1000, 1000])
    expect(old_cell.reload.metadata).to eq("managed_note" => "Keep")
    expect(offers.map { |offer| offer.reload.status }).to eq(%w[cancelled cancelled])
    fresh_offer = create(:world_action_offer, character:, zone: outdoors, target: entrance)
    original = gate_rows

    expect(repair.values).to all(eq(0))
    expect(gate_rows).to eq(original)
    expect(fresh_offer.reload).to be_offered
  end

  it "preserves already imported cells and independent authoring inside the bounded stencil" do
    source = Game::World::StarterCellCatalog.default.at(12, 9)
    managed = create(:map_tile_template, zone: outdoors.name, x: 12, y: 9, passable: false,
      metadata: source.metadata.merge("managed_note" => "Keep", "resource_groups" => []))
    custom = create(:map_tile_template, zone: outdoors.name, x: 10, y: 8,
      metadata: {"source_map" => "managed_cell", "managed_note" => "Keep"})
    before = [managed.attributes, custom.attributes]

    repair

    expect([managed.reload.attributes, custom.reload.attributes]).to eq(before)
  end

  it "rolls back all content changes when an independently authored entrance occupies the gate cell" do
    create(:tile_building, zone: outdoors.name, x: 11, y: 9, building_key: "managed_entrance", destination_zone: central)
    before = gate_rows

    expect { repair }.to raise_error(described_class::Conflict, /independently authored entrance/)
    expect(gate_rows).to eq(before)
  end

  it "does not reopen a managed blocked route or leave a partial import" do
    source = Game::World::StarterCellCatalog.default.at(12, 10)
    create(:map_tile_template, zone: outdoors.name, x: 12, y: 10, passable: false, metadata: source.metadata)
    before = gate_rows

    expect { repair }.to raise_error(described_class::Conflict, /Managed route cell \[12,10\] is blocked/)
    expect(gate_rows).to eq(before)
  end

  it "rejects wrong or duplicate city identities without changing content" do
    law.update!(metadata: law.metadata.merge("city_node_key" => "main"))

    expect { repair }.to raise_error(described_class::Conflict, /Duplicate city node identity/)
    expect(CityHotspot.count).to eq(0)
    expect(TileBuilding.count).to eq(0)
    expect(MapTileTemplate.count).to eq(0)
  end

  it "rolls back updates and capability cancellation if a later record cannot save" do
    entrance = create(:tile_building, zone: outdoors.name, building_key: "outpost_gate", x: 7, y: 0,
      destination_zone: central)
    character = create(:character)
    offer = create(:world_action_offer, character:, zone: outdoors, target: entrance)
    before = gate_rows
    allow_any_instance_of(CityHotspot).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

    expect { repair }.to raise_error(ActiveRecord::RecordInvalid)
    expect(gate_rows).to eq(before)
    expect(offer.reload).to be_offered
  end
end

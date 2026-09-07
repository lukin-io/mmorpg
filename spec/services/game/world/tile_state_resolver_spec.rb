# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TileStateResolver do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  it "composes a tile template, NPC, entrance, and local action on one cell" do
    tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5)
    npc = create(:tile_npc, zone: zone.name, x: 5, y: 5)
    building = create(:tile_building, zone: zone.name, x: 5, y: 5)

    result = described_class.new(character:, position:).call

    expect(result.tile).to eq(tile)
    expect(result.npc).to eq(npc)
    expect(result.building).to eq(building)
    expect(result.local_actions).to contain_exactly(include("type" => "resource_search", "source_id" => "look"))
  end

  it "returns no static local actions for a sparse default cell" do
    result = described_class.new(character:, position:).call

    expect(result.tile).to be_nil
    expect(result.local_actions).to be_empty
  end

  it "keeps complete same-coordinate cell contents isolated in separate regions" do
    other_region = create(:zone, :mvp_outdoor_region)
    contents = [zone, other_region].index_with do |region|
      {
        tile: create(:map_tile_template, :with_resource_search, zone: region.name, x: 5, y: 5),
        npc: create(:tile_npc, zone: region.name, x: 5, y: 5),
        building: create(:tile_building, :world_location, zone: region.name, x: 5, y: 5)
      }
    end

    [zone, other_region].each do |region|
      position.update!(zone: region)
      result = described_class.new(character:, position: position.reload).call

      expect(result).to have_attributes(**contents.fetch(region))
      expect(result.npc_info.fetch(:id)).to eq(contents.fetch(region).fetch(:npc).id)
      expect(result.building_info.fetch(:id)).to eq(contents.fetch(region).fetch(:building).id)
      expect(result.local_actions).to contain_exactly(include("type" => "resource_search"))
    end

    expect(MapTileTemplate.count).to eq(2)
    expect(TileNpc.count).to eq(2)
    expect(TileBuilding.count).to eq(2)
  end

  it "does not expose a captured identifier whose successful flow is deferred" do
    create(:map_tile_template, :with_fishing, zone: zone.name, x: 5, y: 5)

    result = described_class.new(character:, position:).call

    expect(result.local_actions).to be_empty
  end
end

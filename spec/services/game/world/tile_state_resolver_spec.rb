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

  it "does not expose a captured identifier whose successful flow is deferred" do
    create(:map_tile_template, :with_fishing, zone: zone.name, x: 5, y: 5)

    result = described_class.new(character:, position:).call

    expect(result.local_actions).to be_empty
  end
end

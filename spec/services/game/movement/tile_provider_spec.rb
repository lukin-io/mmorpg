# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::TileProvider do
  # This spec covers a bug where TileProvider couldn't find tiles because
  # MapTileTemplate.zone contained corrupted Zone object references
  # instead of zone name strings.
  #
  # Fix: MapTileTemplate.zone= setter converts Zone objects to names

  let(:zone) { create(:zone, name: "Outpost Surroundings") }

  before do
    # Create tiles with proper zone name strings
    create(:map_tile_template, zone: zone.name, x: 0, y: 0, terrain_type: "outdoor", passable: true)
    create(:map_tile_template, zone: zone.name, x: 1, y: 0, terrain_type: "outdoor", passable: true)
    create(:map_tile_template, zone: zone.name, x: 0, y: 1, terrain_type: "outdoor", passable: false)
  end

  describe "#tile_at" do
    subject(:provider) { described_class.new(zone: zone) }

    it "finds tiles by coordinates" do
      tile = provider.tile_at(0, 0)

      expect(tile).not_to be_nil
      expect(tile.x).to eq(0)
      expect(tile.y).to eq(0)
    end

    it "returns nil for non-existent tiles" do
      tile = provider.tile_at(99, 99)

      expect(tile).to be_nil
    end

    it "returns tile with correct passable status" do
      passable_tile = provider.tile_at(0, 0)
      impassable_tile = provider.tile_at(0, 1)

      expect(passable_tile.passable?).to be true
      expect(impassable_tile.passable?).to be false
    end
  end

  describe "#terrain_type_at" do
    subject(:provider) { described_class.new(zone: zone) }

    it "returns explicit tile terrain type" do
      terrain_type = provider.terrain_type_at(0, 0)

      expect(terrain_type).to eq("outdoor")
    end

    it "returns nil for non-existent tiles" do
      terrain_type = provider.terrain_type_at(99, 99)

      expect(terrain_type).to be_nil
    end
  end

  describe "#metadata_at" do
    subject(:provider) { described_class.new(zone: zone) }

    before do
      create(:map_tile_template, zone: zone.name, x: 5, y: 5, terrain_type: "city", metadata: {"building" => "Shop"})
    end

    it "returns tile metadata" do
      metadata = provider.metadata_at(5, 5)

      expect(metadata["building"]).to eq("Shop")
    end

    it "returns empty hash for tiles without metadata" do
      metadata = provider.metadata_at(0, 0)

      expect(metadata).to eq({})
    end

    it "returns empty hash for non-existent tiles" do
      metadata = provider.metadata_at(99, 99)

      expect(metadata).to eq({})
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapTileTemplate, type: :model do
  describe "zone attribute" do
    # This spec covers a bug where Zone objects were stored in the zone column
    # instead of zone name strings, causing movement to fail with:
    # "Tile is not passable" (because no tiles could be found)
    #
    # Fix: Added zone= setter that converts Zone objects to their names

    let(:zone) { create(:zone, name: "Test Zone") }

    it "stores zone as a string name, not an object reference" do
      tile = create(:map_tile_template, zone: zone.name, x: 0, y: 0, terrain_type: "plains")

      expect(tile.zone).to eq("Test Zone")
      expect(tile.zone).not_to start_with("#<Zone:")
    end

    it "converts Zone object to name in setter" do
      tile = MapTileTemplate.new(zone: zone, x: 0, y: 0, terrain_type: "plains")

      expect(tile.zone).to eq("Test Zone")
    end

    it "accepts string zone name directly" do
      tile = MapTileTemplate.new(zone: "Direct Name", x: 0, y: 0, terrain_type: "plains")

      expect(tile.zone).to eq("Direct Name")
    end

    it "validates against corrupted zone values" do
      tile = MapTileTemplate.new(x: 0, y: 0, terrain_type: "plains")
      tile[:zone] = "#<Zone:0x000012345>"  # Bypass setter to simulate corrupted data

      expect(tile).not_to be_valid
      expect(tile.errors[:zone]).to include("must be a zone name string, not a Zone object")
    end
  end

  describe "passability" do
    let(:zone_name) { "Test Zone" }

    it "defaults to passable" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "plains")

      expect(tile.passable).to be true
    end

    it "can be marked as impassable" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "water", passable: false)

      expect(tile.passable).to be false
    end

    it "blocked? returns true when passable is false" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "water", passable: false)

      expect(tile.blocked?).to be true
    end

    it "blocked? returns true when metadata has blocked flag" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "plains", metadata: {"blocked" => true})

      expect(tile.blocked?).to be true
    end
  end

  describe "scopes" do
    let(:zone_name) { "Test Zone" }

    before do
      create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "plains", passable: true)
      create(:map_tile_template, zone: zone_name, x: 1, y: 0, terrain_type: "water", passable: false)
      create(:map_tile_template, zone: "Other Zone", x: 0, y: 0, terrain_type: "plains")
    end

    describe ".in_zone" do
      it "finds tiles by zone name string" do
        tiles = described_class.in_zone(zone_name)

        expect(tiles.count).to eq(2)
      end

      it "finds tiles by Zone object" do
        zone = create(:zone, name: zone_name)
        tiles = described_class.in_zone(zone)

        expect(tiles.count).to eq(2)
      end
    end

    describe ".passable_only" do
      it "filters to only passable tiles" do
        tiles = described_class.in_zone(zone_name).passable_only

        expect(tiles.count).to eq(1)
        expect(tiles.first.passable).to be true
      end
    end
  end
end

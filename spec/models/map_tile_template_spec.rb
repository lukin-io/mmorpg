# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapTileTemplate, type: :model do
  describe "terrain type" do
    it "accepts outdoor cells" do
      expect(build(:map_tile_template, terrain_type: "outdoor")).to be_valid
    end

    it "rejects city cells because captured city movement uses authored nodes" do
      tile = build(:map_tile_template, terrain_type: "city")

      expect(tile).not_to be_valid
      expect(tile.errors[:terrain_type]).to be_present
    end

    it "rejects a null terrain type" do
      tile = build(:map_tile_template, terrain_type: nil)

      expect(tile).not_to be_valid
      expect(tile.errors[:terrain_type]).to be_present
    end
  end

  describe "zone attribute" do
    # This spec covers a bug where Zone objects were stored in the zone column
    # instead of zone name strings, causing movement to fail with:
    # "Tile is not passable" (because no tiles could be found)
    #
    # Fix: Added zone= setter that converts Zone objects to their names

    let(:zone) { create(:zone, name: "Test Zone") }

    it "stores zone as a string name, not an object reference" do
      tile = create(:map_tile_template, zone: zone.name, x: 0, y: 0, terrain_type: "outdoor")

      expect(tile.zone).to eq("Test Zone")
      expect(tile.zone).not_to start_with("#<Zone:")
    end

    it "converts Zone object to name in setter" do
      tile = MapTileTemplate.new(zone: zone, x: 0, y: 0, terrain_type: "outdoor")

      expect(tile.zone).to eq("Test Zone")
    end

    it "accepts string zone name directly" do
      tile = MapTileTemplate.new(zone: "Direct Name", x: 0, y: 0, terrain_type: "outdoor")

      expect(tile.zone).to eq("Direct Name")
    end

    it "validates against corrupted zone values" do
      tile = MapTileTemplate.new(x: 0, y: 0, terrain_type: "outdoor")
      tile[:zone] = "#<Zone:0x000012345>"  # Bypass setter to simulate corrupted data

      expect(tile).not_to be_valid
      expect(tile.errors[:zone]).to include("must be a zone name string, not a Zone object")
    end
  end

  describe "passability" do
    let(:zone_name) { "Test Zone" }

    it "defaults to passable" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "outdoor")

      expect(tile.passable).to be true
    end

    it "can be marked as impassable" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "outdoor", passable: false)

      expect(tile.passable).to be false
    end

    it "blocked? returns true when passable is false" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "outdoor", passable: false)

      expect(tile.blocked?).to be true
    end

    it "blocked? returns true when metadata has blocked flag" do
      tile = create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "outdoor", metadata: {"blocked" => true})

      expect(tile.blocked?).to be true
    end
  end

  describe "source-backed cell art" do
    it "resolves a configured 100px image-cell slice" do
      tile = build(:map_tile_template, :with_cell_art)

      expect(tile).to be_valid
      expect(tile.cell_art).to eq(
        "key" => "forpost_terrain",
        "column" => 7,
        "row" => 7
      )
      expect(tile.cell_art_presentation).to have_attributes(
        asset: "world/forpost-terrain.png",
        background_x: -700,
        background_y: -700
      )
    end

    it "allows an ordinary sparse cell without an art override" do
      tile = build(:map_tile_template, metadata: {})

      expect(tile).to be_valid
      expect(tile.cell_art).to be_nil
    end

    it "accepts the last zero-based coordinate in the configured sheet" do
      tile = build(:map_tile_template, :with_cell_art_at_sheet_edge)

      expect(tile).to be_valid
      expect(tile.cell_art_presentation).to have_attributes(
        column: 9,
        row: 9,
        background_x: -900,
        background_y: -900
      )
    end

    it "rejects an art override without Neverlands source metadata" do
      tile = build(
        :map_tile_template,
        metadata: {
          "cell_art" => {"key" => "forpost_terrain", "column" => 0, "row" => 0}
        }
      )

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata]).to include("cell_art requires a Neverlands source_map")
    end

    it "rejects an unknown art key" do
      tile = build(:map_tile_template, :with_invalid_cell_art)

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata]).to include(
        "cell_art must use a configured 100x100 source-backed art slice"
      )
    end

    it "rejects malformed, null-coordinate, and out-of-bounds art references" do
      malformed = build(:map_tile_template, metadata: {"source_map" => "m_1", "cell_art" => "gate.png"})
      null_coordinate = build(
        :map_tile_template,
        metadata: {
          "source_map" => "m_1",
          "cell_art" => {"key" => "forpost_terrain", "column" => nil, "row" => 0}
        }
      )
      out_of_bounds = build(
        :map_tile_template,
        metadata: {
          "source_map" => "m_1",
          "cell_art" => {"key" => "forpost_terrain", "column" => 10, "row" => 0}
        }
      )

      expect(malformed).not_to be_valid
      expect(malformed.errors[:metadata]).to include("cell_art must be an object")
      expect(null_coordinate).not_to be_valid
      expect(out_of_bounds).not_to be_valid
    end

    it "rejects negative and non-numeric sheet coordinates" do
      negative = build(
        :map_tile_template,
        metadata: {
          "source_map" => "m_1",
          "cell_art" => {"key" => "forpost_terrain", "column" => -1, "row" => 0}
        }
      )
      non_numeric = build(
        :map_tile_template,
        metadata: {
          "source_map" => "m_1",
          "cell_art" => {"key" => "forpost_terrain", "column" => "west", "row" => 0}
        }
      )

      expect(negative).not_to be_valid
      expect(non_numeric).not_to be_valid
    end
  end

  describe "source-backed local actions" do
    it "normalizes and returns an active resource-search action" do
      tile = build(:map_tile_template, :with_resource_search)

      expect(tile).to be_valid
      expect(tile.local_action("resource_search")).to include(
        "source_id" => "look",
        "label" => "Look Around"
      )
    end

    it "recognizes the captured fishing action identifier" do
      tile = build(:map_tile_template, :with_fishing)

      expect(tile).to be_valid
      expect(MapTileTemplate.world_action_type_for("fishing")).to eq("fish")
      expect(MapTileTemplate.local_action_implemented?("fishing")).to be false
      expect(tile.local_action("fishing")).to include("source_id" => "fis")
    end

    it "marks only the captured launch action as implemented" do
      expect(described_class::LOCAL_ACTION_DEFINITIONS.transform_values { |definition| definition["source_id"] }).to eq(
        "resource_search" => "look",
        "fishing" => "fis",
        "drinking" => "dri",
        "digging" => "dig"
      )
      expect(MapTileTemplate.local_action_implemented?("resource_search")).to be true
      expect(MapTileTemplate.local_action_implemented?("drinking")).to be false
      expect(MapTileTemplate.local_action_implemented?("digging")).to be false
      expect(MapTileTemplate.local_action_implemented?(nil)).to be false
    end

    it "does not expose an inactive local action" do
      tile = build(:map_tile_template, :with_inactive_resource_search)

      expect(tile).to be_valid
      expect(tile.active_local_actions).to be_empty
    end

    it "rejects an unsupported generic action" do
      tile = build(
        :map_tile_template,
        metadata: {"local_actions" => [{"type" => "generic_gather", "source_id" => "gather"}]}
      )

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata].join).to include("unsupported local action")
    end

    it "rejects a mismatched Neverlands source id" do
      tile = build(
        :map_tile_template,
        metadata: {"local_actions" => [{"type" => "resource_search", "source_id" => "inspect"}]}
      )

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata].join).to include("must use source id look")
    end

    it "rejects duplicate action types on one cell" do
      tile = build(
        :map_tile_template,
        metadata: {
          "local_actions" => [
            {"type" => "resource_search", "source_id" => "look"},
            {"type" => "resource_search", "source_id" => "look"}
          ]
        }
      )

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata].join).to include("duplicate local action types")
    end

    it "rejects null and non-object local action entries" do
      tile = build(:map_tile_template, metadata: {"local_actions" => [nil]})

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata]).to include("local action must be an object")
    end

    it "rejects a non-array local action container" do
      tile = build(:map_tile_template, metadata: {"local_actions" => {"type" => "resource_search"}})

      expect(tile).not_to be_valid
      expect(tile.errors[:metadata]).to include("local_actions must be an array")
    end

    it "allows the zero-coordinate region boundary" do
      tile = build(:map_tile_template, :at_boundary, :with_resource_search)

      expect(tile).to be_valid
    end

    it "rejects negative coordinates" do
      tile = build(:map_tile_template, x: -1, y: 0)

      expect(tile).not_to be_valid
      expect(tile.errors[:x]).to be_present
    end

    it "rejects null coordinates" do
      tile = build(:map_tile_template, x: nil, y: 0)

      expect(tile).not_to be_valid
      expect(tile.errors[:x]).to be_present
    end
  end

  describe "scopes" do
    let(:zone_name) { "Test Zone" }

    before do
      create(:map_tile_template, zone: zone_name, x: 0, y: 0, terrain_type: "outdoor", passable: true)
      create(:map_tile_template, zone: zone_name, x: 1, y: 0, terrain_type: "outdoor", passable: false)
      create(:map_tile_template, zone: "Other Zone", x: 0, y: 0, terrain_type: "outdoor")
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

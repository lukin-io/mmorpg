# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CellArtCatalog do
  before { described_class.reload! }

  describe ".resolve" do
    let(:valid_definition) do
      {
        "asset" => "world/forpost-terrain.png",
        "cell_width" => 100,
        "cell_height" => 100,
        "columns" => 10,
        "rows" => 10,
        "source_reference" => "neverlands_live_movement"
      }
    end

    it "resolves a configured 100px Forpost atlas slice" do
      presentation = described_class.resolve(
        "key" => "forpost_terrain",
        "column" => 7,
        "row" => 7
      )

      expect(presentation).to have_attributes(
        key: "forpost_terrain",
        asset: "world/forpost-terrain.png",
        cell_width: 100,
        cell_height: 100,
        sheet_width: 1000,
        sheet_height: 1000,
        background_x: -700,
        background_y: -700
      )
    end

    it "defaults omitted sheet coordinates to the first slice" do
      presentation = described_class.resolve("key" => "forpost_terrain")

      expect(presentation).to have_attributes(column: 0, row: 0, background_x: 0, background_y: 0)
    end

    it "accepts the last zero-based sheet coordinate" do
      presentation = described_class.resolve(
        "key" => "forpost_terrain",
        "column" => 9,
        "row" => 9
      )

      expect(presentation).to have_attributes(column: 9, row: 9, background_x: -900, background_y: -900)
    end

    it "rejects malformed, unknown, null, negative, and out-of-bounds references" do
      invalid_references = [
        nil,
        "forpost_terrain",
        {},
        [["key"]],
        {"key" => "unknown_art"},
        {"key" => "forpost_terrain", "column" => nil, "row" => 0},
        {"key" => "forpost_terrain", "column" => -1, "row" => 0},
        {"key" => "forpost_terrain", "column" => 10, "row" => 0},
        {"key" => "forpost_terrain", "column" => 0, "row" => 10},
        {"key" => "forpost_terrain", "column" => "east", "row" => 0},
        {"key" => "forpost_terrain", "column" => 0.5, "row" => 0},
        {"key" => "forpost_terrain", "column" => 0, "row" => 0.5}
      ]

      expect(invalid_references).to all(satisfy { |reference| described_class.resolve(reference).nil? })
    end

    it "rejects unsafe and missing project assets" do
      invalid_assets = ["gate.png", "world/../gate.png", "world/missing-cell-art.png",
        "world//forpost-terrain.png", "world/forpost-terrain.png?query", "world/x');background:red;('"]

      invalid_assets.each do |asset|
        allow(described_class).to receive(:config).and_return(
          "test_art" => valid_definition.merge("asset" => asset)
        )

        expect(described_class.resolve("key" => "test_art")).to be_nil
      end
    end

    it "rejects non-100px cells and invalid sheet dimensions" do
      invalid_dimensions = [
        {"cell_width" => 99},
        {"cell_height" => 101},
        {"columns" => 0},
        {"columns" => nil},
        {"rows" => -1},
        {"rows" => "many"}
      ]

      invalid_dimensions.each do |attributes|
        allow(described_class).to receive(:config).and_return(
          "test_art" => valid_definition.merge(attributes)
        )

        expect(described_class.resolve("key" => "test_art")).to be_nil
      end
    end

    it "rejects art without a Neverlands source reference" do
      allow(described_class).to receive(:config).and_return(
        "test_art" => valid_definition.merge("source_reference" => nil)
      )

      expect(described_class.resolve("key" => "test_art")).to be_nil
    end

    it "rejects malformed hash-like catalog definitions without raising" do
      allow(described_class).to receive(:config).and_return("test_art" => [["asset"]])

      expect(described_class.resolve("key" => "test_art")).to be_nil
    end

    it "suppresses only the configured building on its exact painted slice" do
      gate = described_class.resolve("key" => "forpost_starter", "column" => 6, "row" => 6)
      grass = described_class.resolve("key" => "forpost_starter", "column" => 7, "row" => 6,
        "painted_building_key" => "outpost_gate")

      expect(gate.painted_building?("outpost_gate")).to be true
      expect(gate.painted_building?("different_gate")).to be false
      expect(gate.painted_building?(nil)).to be false
      expect(grass.painted_building?("outpost_gate")).to be false
    end

    it "does not hide a marker when the flag lacks an explicit anchor or is disabled" do
      definition = valid_definition.merge("landmarks_in_art" => true)
      allow(described_class).to receive(:config).and_return("test_art" => definition)
      expect(described_class.resolve("key" => "test_art").painted_building?("outpost_gate")).to be false
      definition.merge!("landmarks_in_art" => false,
        "painted_landmarks" => [{"column" => 0, "row" => 0, "building_key" => "outpost_gate"}])
      expect(described_class.resolve("key" => "test_art").painted_building?("outpost_gate")).to be false
    end

    it "rejects malformed, duplicate and out-of-bounds painted landmark mappings" do
      anchor = {"column" => 0, "row" => 0, "building_key" => "outpost_gate"}
      invalid_mappings = [
        nil, true, {}, ["outpost_gate"], [anchor.merge("column" => -1)], [anchor.merge("row" => 10)],
        [anchor.merge("column" => 0.5)], [anchor.merge("building_key" => "")],
        [anchor.merge("building_key" => "../gate")], [anchor.merge("unknown" => true)],
        [anchor, anchor.merge("building_key" => "second")], [anchor, anchor.merge("column" => 1)]
      ]
      invalid_mappings.each do |mapping|
        allow(described_class).to receive(:config).and_return("test_art" => valid_definition.merge("painted_landmarks" => mapping))
        expect(described_class.resolve("key" => "test_art")).to be_nil
      end
    end

    context "with optional physical cell PNGs" do
      let(:slice_definition) do
        valid_definition.merge("slices_directory" => "world/cells/spec-starter", "landmarks_in_art" => true)
      end
      let(:slice_asset) { "world/cells/spec-starter/7_9.png" }
      let(:reference) { {"key" => "test_art", "column" => 7, "row" => 9} }

      before do
        allow(described_class).to receive(:config).and_return("test_art" => slice_definition)
        allow(described_class).to receive(:asset_exists?).and_call_original
      end

      it "keeps logical coordinates but uses 100px geometry and zero offset for an existing cell PNG" do
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(true)

        expect(described_class.resolve(reference)).to have_attributes(
          asset: slice_asset, column: 7, row: 9, cell_width: 100, cell_height: 100,
          sheet_width: 100, sheet_height: 100, background_x: 0, background_y: 0,
          physical_slice: true, landmarks_in_art: true
        )
      end

      it "recovers the matching master crop when an individual PNG is absent" do
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(false)

        expect(described_class.resolve(reference)).to have_attributes(
          asset: "world/forpost-terrain.png", column: 7, row: 9,
          sheet_width: 1000, sheet_height: 1000, background_x: -700, background_y: -900,
          physical_slice: false, landmarks_in_art: true
        )
      end

      it "rejects unsafe or malformed directories and requests outside the master grid" do
        [nil, false, "", "world", "/world/cells", "world/../cells", "world//cells", "world/cells/", "world/cells.png"].each do |directory|
          slice_definition["slices_directory"] = directory
          expect(described_class.resolve(reference)).to be_nil
        end
        slice_definition["slices_directory"] = "world/cells/spec-starter"
        expect(described_class.resolve(reference.merge("column" => 10))).to be_nil
        expect(described_class.resolve(reference.merge("row" => -1))).to be_nil
      end

      it "uses only a strictly boolean catalog landmark flag, ignoring metadata overrides" do
        ["true", 1, nil].each do |invalid|
          slice_definition["landmarks_in_art"] = invalid
          expect(described_class.resolve(reference)).to be_nil
        end
        slice_definition["landmarks_in_art"] = false
        expect(described_class.resolve(reference.merge("landmarks_in_art" => true))).to have_attributes(landmarks_in_art: false)
        slice_definition["landmarks_in_art"] = true
        expect(described_class.resolve(reference.merge("landmarks_in_art" => false,
          "slices_directory" => "world/attacker", "asset" => "world/attacker.png"))).to have_attributes(
          landmarks_in_art: true, asset: "world/forpost-terrain.png"
        )
      end

      it "requires the safe master asset even when a cell PNG exists" do
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(true)
        allow(described_class).to receive(:asset_exists?).with("world/forpost-terrain.png").and_return(false)

        expect(described_class.resolve(reference)).to be_nil
      end
    end
  end

  describe ".valid_reference?" do
    it "reports whether persisted metadata resolves safely" do
      expect(described_class.valid_reference?("key" => "forpost_terrain", "column" => 0, "row" => 0)).to be true
      expect(described_class.valid_reference?("key" => "missing_art", "column" => 0, "row" => 0)).to be false
    end
  end

  describe ".config" do
    it "caches the parsed catalog until explicitly reloaded" do
      first_config = described_class.config

      expect(described_class.config).to equal(first_config)
      expect(described_class.reload!).not_to equal(first_config)
    end
  end
end

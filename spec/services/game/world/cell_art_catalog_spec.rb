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
        {"key" => "unknown_art"},
        {"key" => "forpost_terrain", "column" => nil, "row" => 0},
        {"key" => "forpost_terrain", "column" => -1, "row" => 0},
        {"key" => "forpost_terrain", "column" => 10, "row" => 0},
        {"key" => "forpost_terrain", "column" => 0, "row" => 10},
        {"key" => "forpost_terrain", "column" => "east", "row" => 0}
      ]

      expect(invalid_references).to all(satisfy { |reference| described_class.resolve(reference).nil? })
    end

    it "rejects unsafe and missing project assets" do
      invalid_assets = ["gate.png", "world/../gate.png", "world/missing-cell-art.png"]

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

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CellArtCatalog do
  before { described_class.reload! }

  describe ".resolve_for_tile" do
    let(:zone) do
      Zone.new(name: "Outpost Surroundings", location_type: "outdoor", width: 1000, height: 1000,
        metadata: {"source_map" => "m_1001_999"})
    end

    it "resolves every sparse starter coordinate to its own continuous landscape slice without SQL" do
      region = zone
      queries = []
      measured_thread = Thread.current
      # Pool maintenance can emit SQL on another thread. Keep every SQL event
      # from this synchronous lookup, including schema/setup statements.
      subscriber = lambda do |*arguments|
        queries << arguments.last.fetch(:sql) if Thread.current.equal?(measured_thread)
      end
      presentations = []
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        (0..20).each do |x|
          (2..14).each do |y|
            art = described_class.resolve_for_tile(nil, zone: region, x:, y:)
            expect(art).to have_attributes(key: "forpost_starter", column: x, row: y - 2,
              asset: "world/cells/forpost-starter/#{x}_#{y - 2}.png")
            presentations << art.asset
          end
        end
      end

      expect(presentations.uniq.size).to eq(273)
      expect(queries).to be_empty
    end

    it "resolves all 39 surveyed western margin cells without loading or extending gameplay records" do
      region = zone
      queries = []
      measured_thread = Thread.current
      subscriber = lambda do |*arguments|
        queries << arguments.last.fetch(:sql) if Thread.current.equal?(measured_thread)
      end
      presentations = []
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        (-3..-1).each do |x|
          (2..14).each do |y|
            art = described_class.resolve_for_tile(nil, zone: region, x:, y:)
            expect(art).to have_attributes(key: "forpost_starter_west", column: x + 3, row: y - 2,
              asset: "world/cells/forpost-starter-west/#{x + 3}_#{y - 2}.png", physical_slice: true,
              landmarks_in_art: false)
            presentations << art.asset
          end
        end
      end

      expect(presentations.uniq.size).to eq(39)
      expect(queries).to be_empty
      expect(region).to have_attributes(width: 1000, height: 1000)
    end

    it "preserves explicit valid art at the western margin and fails closed for invalid references" do
      %w[forpost_terrain forpost_starter forpost_starter_west].each do |key|
        reference = {"key" => key, "column" => 1, "row" => 1}
        expect(described_class.resolve_for_tile(reference, zone:, x: -1, y: 9)).to have_attributes(key:, column: 1, row: 1)
      end
      ["malformed", {"key" => "unknown"}, {"key" => "forpost_starter_west", "column" => 3}].each do |reference|
        expect(described_class.resolve_for_tile(reference, zone:, x: -1, y: 9)).to be_nil
      end
    end

    it "uses the same coordinate default for the two retired starter-art defaults" do
      %w[forpost_terrain forpost_pond].each do |key|
        art = described_class.resolve_for_tile({"key" => key, "column" => 1, "row" => 1}, zone:, x: 11, y: 9)
        expect(art).to have_attributes(key: "forpost_starter", column: 11, row: 7)
        expect(art.painted_building?("outpost_east_gate")).to be(true)
        expect(art.painted_building?("moved_gate")).to be(false)
      end
    end

    it "preserves independently authored art and deliberately edited starter coordinates" do
      config = described_class.config.deep_dup
      config["managed_art"] = config.fetch("forpost_terrain").deep_dup
      allow(described_class).to receive(:config).and_return(config)
      ["managed_art", "forpost_starter"].each do |key|
        art = described_class.resolve_for_tile({"key" => key, "column" => 3, "row" => 4}, zone:, x: 11, y: 9)
        expect(art).to have_attributes(key:, column: 3, row: 4)
      end
    end

    it "does not replace an explicit invalid reference with a different semantic artwork selection" do
      ["malformed", {"key" => "missing_custom_art"}, {"key" => "forpost_starter", "column" => 21}].each do |reference|
        expect(described_class.resolve_for_tile(reference, zone:, x: 11, y: 9)).to be_nil
      end
    end

    it "does not extend the starter illustration outside its captured rectangle" do
      [[-4, 9], [21, 9], [-1, 1], [-1, 15], [11, 1], [11, 15], [nil, 9], [11, "9"]].each do |x, y|
        expect(described_class.resolve_for_tile(nil, zone:, x:, y:)).to be_nil
      end
      reference = {"key" => "forpost_terrain", "column" => 1, "row" => 1}
      expect(described_class.resolve_for_tile(reference, zone:, x: 21, y: 9)).to have_attributes(key: "forpost_terrain")
    end

    it "requires the canonical region name, type, bounds and source identity" do
      [{name: "Another region"}, {location_type: "city"}, {width: 999}, {height: 999},
        {metadata: {"source_map" => "another_source"}}].each do |attributes|
        other = zone.dup
        other.assign_attributes(attributes)
        expect(described_class.resolve_for_tile(nil, zone: other, x: 11, y: 9)).to be_nil
        expect(described_class.resolve_for_tile(nil, zone: other, x: -1, y: 9)).to be_nil
      end
      expect(described_class.resolve_for_tile(nil, zone: nil, x: 11, y: 9)).to be_nil
    end

    it "fails closed for the starter default instead of restoring a legacy atlas when its catalog is unavailable" do
      config = described_class.config.deep_dup.except("forpost_starter")
      allow(described_class).to receive(:config).and_return(config)
      reference = {"key" => "forpost_terrain", "column" => 1, "row" => 1}

      expect(described_class.resolve_for_tile(reference, zone:, x: 11, y: 9)).to be_nil
      expect(described_class.resolve_for_tile(nil, zone:, x: 11, y: 9)).to be_nil
    end

    it "does not substitute a legacy atlas when the exact starter PNG is missing" do
      allow(described_class).to receive(:asset_exists?).and_call_original
      allow(described_class).to receive(:asset_exists?).with("world/cells/forpost-starter/11_7.png").and_return(false)
      reference = {"key" => "forpost_terrain", "column" => 1, "row" => 1}

      expect(described_class.resolve_for_tile(reference, zone:, x: 11, y: 9)).to be_nil
      expect(described_class.resolve(reference)).to have_attributes(key: "forpost_terrain")
    end

    it "does not substitute the western master or another cell when a margin PNG is missing" do
      allow(described_class).to receive(:asset_exists?).and_call_original
      allow(described_class).to receive(:asset_exists?).with("world/cells/forpost-starter-west/2_7.png").and_return(false)

      expect(described_class.resolve_for_tile(nil, zone:, x: -1, y: 9)).to be_nil
      expect(described_class.resolve("key" => "forpost_starter_west", "column" => 2, "row" => 7)).to be_nil
    end
  end

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

      it "does not load the authoring master when an individual PNG is absent" do
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(false)

        expect(described_class.resolve(reference)).to be_nil
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
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(true)
        ["true", 1, nil].each do |invalid|
          slice_definition["landmarks_in_art"] = invalid
          expect(described_class.resolve(reference)).to be_nil
        end
        slice_definition["landmarks_in_art"] = false
        expect(described_class.resolve(reference.merge("landmarks_in_art" => true))).to have_attributes(landmarks_in_art: false)
        slice_definition["landmarks_in_art"] = true
        expect(described_class.resolve(reference.merge("landmarks_in_art" => false,
          "slices_directory" => "world/attacker", "asset" => "world/attacker.png"))).to have_attributes(
          landmarks_in_art: true, asset: slice_asset
        )
      end

      it "resolves the physical PNG without depending on its authoring master being deployed" do
        allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(true)
        allow(described_class).to receive(:asset_exists?).with("world/forpost-terrain.png").and_return(false)

        expect(described_class.resolve(reference)).to have_attributes(asset: slice_asset, physical_slice: true)
      end

      context "with optional high-density cell PNGs" do
        let(:high_density_asset) { "world/cells/spec-starter-2x/7_9.png" }

        before do
          slice_definition["high_density_slices_directory"] = "world/cells/spec-starter-2x"
          allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(true)
          allow(described_class).to receive(:asset_exists?).with(high_density_asset).and_return(true)
        end

        it "offers the same coordinate at 2x without changing logical cell or background geometry" do
          expect(described_class.resolve(reference)).to have_attributes(
            asset: slice_asset, high_density_asset:, column: 7, row: 9,
            cell_width: 100, cell_height: 100, sheet_width: 100, sheet_height: 100,
            background_x: 0, background_y: 0, physical_slice: true
          )
        end

        it "retains the mandatory 1x image when the optional 2x image is missing" do
          allow(described_class).to receive(:asset_exists?).with(high_density_asset).and_return(false)

          expect(described_class.resolve(reference)).to have_attributes(asset: slice_asset, high_density_asset: nil)
        end

        it "rejects a missing base cell even when the high-density PNG exists" do
          allow(described_class).to receive(:asset_exists?).with(slice_asset).and_return(false)

          expect(described_class.resolve(reference)).to be_nil
        end

        it "rejects unsafe high-density directories and density configuration for nonsliced sheets" do
          [nil, false, "", "/world/cells", "world/../cells", "world//cells", "world/cells/", "world/cells.png"].each do |directory|
            slice_definition["high_density_slices_directory"] = directory
            expect(described_class.resolve(reference)).to be_nil
          end
          slice_definition["high_density_slices_directory"] = "world/cells/spec-starter-2x"
          slice_definition.delete("slices_directory")

          expect(described_class.resolve(reference)).to be_nil
        end

        it "ignores per-tile density paths and returns no enhanced image for ordinary catalog entries" do
          untrusted = reference.merge("high_density_slices_directory" => "world/attacker",
            "high_density_asset" => "world/attacker.png", "cell_width" => 200)

          expect(described_class.resolve(untrusted)).to have_attributes(high_density_asset:, cell_width: 100)
          slice_definition.delete("high_density_slices_directory")
          expect(described_class.resolve(untrusted)).to have_attributes(asset: slice_asset, high_density_asset: nil)
        end
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

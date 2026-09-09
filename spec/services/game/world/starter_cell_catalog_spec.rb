# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::StarterCellCatalog do
  let(:data) { YAML.safe_load_file(described_class::CONFIG_PATH, aliases: false) }
  let(:catalog) { described_class.new(data:) }

  it "covers every source coordinate in the bounded starter rectangle exactly once" do
    expect(catalog.zone_name).to eq("Outpost Surroundings")
    expect(catalog.cells.map { |cell| [cell.x, cell.y] }).to match_array((0..20).to_a.product((2..14).to_a))
    expect(catalog.at(-1, 2)).to be_nil
    expect(catalog.at(20, 15)).to be_nil
    expect(catalog.at("6", "8")).to be_nil
  end

  it "maps both gates, the village, and pond to the captured source and local coordinates" do
    {
      [6, 8] => [[1000, 1000], "8-259"],
      [4, 6] => [[998, 998], "8-197"],
      [11, 9] => [[1005, 1001], "8-294"],
      [13, 10] => [[1007, 1002], "8-326"]
    }.each do |coordinates, (source, atlas_id)|
      cell = catalog.at(*coordinates)
      expect(cell.passable).to be(true)
      expect(cell.metadata).to include("source_coordinates" => source, "source_map" => "m_#{source.join('_')}")
      expect(cell.metadata.dig("atlas", "id")).to eq(atlas_id)
    end
  end

  it "preserves explicit inactive cells instead of using sparse passable defaults" do
    expect(catalog.at(7, 8).passable).to be(false)
    expect(catalog.at(6, 9).passable).to be(false)
    expect(catalog.at(5, 7).passable).to be(true)
    expect(catalog.at(12, 10).passable).to be(true)
  end

  it "keeps water, fish, herb identities and level-zero NPC ranges as evidence without inventing gameplay" do
    pond = catalog.at(13, 10).metadata
    rat = catalog.at(7, 7).metadata

    expect(pond.fetch("atlas")).to include("has_water" => true, "has_fish" => true, "herb_groups" => [2], "npc_annotations" => [])
    expect(rat.dig("atlas", "npc_annotations")).to eq([{"name" => "Крысы", "min_level" => 0, "max_level" => 4}])
    expect(pond.keys).to match_array(%w[source_map source_coordinates atlas])
    expect(rat.keys).not_to include("encounter_rosters", "local_actions", "terrain_type", "cell_art")
    expect(pond.dig("atlas", "source")).to include("url" => "https://nlservice.cc/map/", "captured_at" => "2026-09-09")
  end

  it "does not confuse a village-area label with the exact village entrance" do
    expect(catalog.at(5, 7).metadata.dig("atlas", "kind")).to eq("active")
    expect(catalog.at(4, 6).metadata.dig("atlas", "kind")).to eq("city")
  end

  it "copies and deeply freezes facts so callers cannot alter cached source evidence" do
    loaded = catalog
    data.fetch("cells").first.fetch("atlas")["label"] = "changed"
    data.fetch("atlas_source")["captured_at"] = "changed"

    expect(loaded.at(0, 2).metadata.dig("atlas", "label")).not_to eq("changed")
    expect { loaded.cells << loaded.cells.first }.to raise_error(FrozenError)
    expect { loaded.at(7, 7).metadata.dig("atlas", "npc_annotations").first["min_level"] = 2 }.to raise_error(FrozenError)
    expect { loaded.at(13, 10).metadata.dig("atlas", "source", "captured_at").replace("changed") }.to raise_error(FrozenError)
  end

  it "rejects missing, extra, non-string and malformed header keys" do
    [nil, [], data.except("cells"), data.merge("terrain" => "forest"), data.merge(cells: [])].each do |invalid|
      expect { described_class.new(data: invalid) }.to raise_error(described_class::InvalidConfigurationError, /catalog must contain exactly/)
    end
  end

  it "rejects incomplete rectangles and duplicate source coordinates" do
    data.fetch("cells").pop
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /must contain all 273 surveyed coordinates/)

    data.fetch("cells") << data.fetch("cells").first.deep_dup
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /duplicate source coordinates/)
  end

  it "rejects wrong, out-of-bounds, fractional, and malformed source coordinates" do
    [[993, 994], [1015, 994], [994, 1007], [994.5, 994], ["994", 994], [994], nil].each do |invalid|
      data.fetch("cells").first["source_coordinates"] = invalid
      expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /source_coordinates/)
    end
  end

  it "rejects mismatched atlas coordinates and duplicate atlas IDs" do
    data.fetch("cells").first.fetch("atlas")["coordinates"] = [0, 0]
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /coordinates do not match/)
    data.fetch("cells").first.fetch("atlas")["coordinates"] = [72, 40]
    data.fetch("cells").first.fetch("atlas")["id"] = data.fetch("cells").second.dig("atlas", "id")
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /duplicate atlas IDs/)
  end

  it "rejects malformed atlas IDs, missing keys, and undocumented mechanics" do
    data.fetch("cells").first.fetch("atlas")["id"] = "8/73"
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /id must be/)
    data.fetch("cells").first.fetch("atlas")["id"] = "8-73"
    data.fetch("cells").first.fetch("atlas")["attack_probability"] = 0.5
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /atlas must contain exactly/)
  end

  it "rejects coerced or missing activity, water and fishing flags" do
    %w[active has_water has_fish].each do |flag|
      [nil, "true", "false", 0, 1, []].each do |invalid|
        changed = data.deep_dup
        changed.fetch("cells").first.fetch("atlas")[flag] = invalid
        expect { described_class.new(data: changed) }.to raise_error(described_class::InvalidConfigurationError, /#{flag} must be true or false/)
      end
    end
  end

  it "rejects invalid herb-group identities without treating zero as an actual group" do
    [nil, "2", [0], [-1], [2, 2], ["2"], (1..33).to_a].each do |invalid|
      data.fetch("cells").first.fetch("atlas")["herb_groups"] = invalid
      expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /herb_groups/)
    end
  end

  it "rejects malformed NPC annotations, reversed ranges and combat-roster fields" do
    [nil, {}, [{"name" => "Rat", "min_level" => 4, "max_level" => 0}],
      [{"name" => "Rat", "min_level" => -1, "max_level" => 4}],
      [{"name" => "Rat", "min_level" => "0", "max_level" => 4}],
      [{"name" => "Rat", "min_level" => 0, "max_level" => 1001}],
      [{"name" => "", "min_level" => 0, "max_level" => 4}],
      [{"name" => "Rat", "min_level" => 0, "max_level" => 4, "hp" => 100}]].each do |invalid|
      data.fetch("cells").first.fetch("atlas")["npc_annotations"] = invalid
      expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /npc_annotations/)
    end
  end

  it "rejects reversed, oversized or negative local bounds and malformed offsets" do
    [[1014, 994], [993, 1014], [994, 1994], [994, "1014"]].each do |invalid|
      changed = data.deep_dup
      changed.fetch("source_bounds")["x"] = invalid
      expect { described_class.new(data: changed) }.to raise_error(described_class::InvalidConfigurationError, /source_bounds/)
    end
    data.fetch("source_bounds")["x"] = [994, 1094]
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /at most 1000 cells/)
    data["source_origin"] = nil
    expect { catalog }.to raise_error(described_class::InvalidConfigurationError, /source_origin/)
  end

  it "fails clearly on unreadable and malformed YAML before exposing a catalog" do
    Tempfile.create(["starter-cells", ".yml"]) do |file|
      file.write("cells: [")
      file.flush
      expect { described_class.load(path: file.path) }.to raise_error(described_class::InvalidConfigurationError, /could not be loaded/)
    end
    expect { described_class.load(path: Rails.root.join("tmp/absent-starter-cells.yml")) }
      .to raise_error(described_class::InvalidConfigurationError, /could not be loaded/)
  end

  it "only publishes a replacement default after the entire catalog validates" do
    original = described_class.default
    allow(described_class).to receive(:load).and_raise(described_class::InvalidConfigurationError, "invalid replacement")

    expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError)
    expect(described_class.default).to equal(original)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityCatalog do
  it "defines the observed five-node Forpost graph" do
    expect(described_class::STARTER_NODE_KEY).to eq("main")
    expect(described_class::NODES.keys).to contain_exactly(
      "main", "forpost1", "forpost2", "forpost3", "forpost4"
    )

    expect(described_class::NODES.transform_values { |node| node["links"].keys }).to eq(
      "main" => %w[forpost3 forpost1],
      "forpost1" => %w[main forpost2 forpost4],
      "forpost2" => %w[forpost1],
      "forpost3" => %w[main],
      "forpost4" => %w[forpost1]
    )

    described_class::NODES.each do |node_key, node|
      node["links"].each_key do |destination_key|
        expect(described_class.node(destination_key)).to be_present,
          "expected #{node_key} destination #{destination_key} to exist"
      end
    end
  end

  it "keeps interactive features on their currently observed districts" do
    expect(described_class::NODES.transform_values { |node| node["features"].keys }).to eq(
      "main" => %w[arena shop hospital],
      "forpost1" => %w[airship_station market],
      "forpost2" => [],
      "forpost3" => [],
      "forpost4" => []
    )
    expect(described_class.node("main").dig("features", "arena", "required_level")).to eq(0)
  end

  it "pairs both captured gates with their exact city nodes and outdoor cells" do
    expect(described_class::GATES.keys).to contain_exactly("west", "east")
    expect(described_class::GATES.fetch("west")).to include(
      "name" => "City Exit",
      "presence_label" => "Outpost, West Gate",
      "node_key" => "main",
      "local_coordinates" => [6, 8],
      "source_coordinates" => [1000, 1000],
      "source_map" => "m_1000_1000"
    )
    expect(described_class::GATES.fetch("east")).to include(
      "name" => "City Exit",
      "presence_label" => "Outpost, East Gate",
      "node_key" => "forpost4",
      "local_coordinates" => [11, 9],
      "source_coordinates" => [1005, 1001],
      "source_map" => "m_1005_1001"
    )
  end

  it "makes the existing Law Quarter gate an action without a duplicate landmark" do
    expect(described_class.hotspot_presentation("forpost4", "east_gate")).to eq(
      "box" => [46, 343, 371, 257]
    )
    expect(described_class.presentation("forpost4").fetch("landmarks")).not_to have_key("city_exit")
  end

  it "uses the observed native scene and project image dimensions" do
    expect(described_class::SCENE_WIDTH).to eq(1250)
    expect(described_class::SCENE_HEIGHT).to eq(600)
    expect(described_class::IMAGE_WIDTH).to eq(1536)
    expect(described_class::IMAGE_HEIGHT).to eq(1024)
  end

  it "defines pixel geometry for every seeded city action" do
    described_class::NODES.each do |node_key, node|
      expected_hotspot_keys = node["links"].keys.map { |destination| "go_#{destination}" }
      expected_hotspot_keys.concat(node["features"].keys)
      described_class::GATES.each do |gate_key, gate|
        expected_hotspot_keys << "#{gate_key}_gate" if gate["node_key"] == node_key
      end

      presentation = described_class.presentation(node_key)

      expect(presentation.fetch("image_offset").size).to eq(2)
      expect(presentation.fetch("focus").size).to eq(2)
      expect(presentation.fetch("hotspots").keys).to contain_exactly(*expected_hotspot_keys)
      presentation.fetch("hotspots").each_value do |geometry|
        left, top, width, height = geometry.fetch("box")
        expect(left).to be_between(0, described_class::SCENE_WIDTH)
        expect(top).to be_between(0, described_class::SCENE_HEIGHT)
        expect(width).to be_positive
        expect(height).to be_positive
      end
    end
  end

  it "keeps current Central Square and Residential Quarter geometry explicit" do
    expect(described_class.hotspot_presentation("main", "shop")).to include(
      "box" => [0, 165, 402, 360]
    )
    expect(described_class.hotspot_presentation("main", "go_forpost1")).to include(
      "box" => [900, 496, 68, 104],
      "direction" => "southeast"
    )
    expect(described_class.presentation("forpost1").dig("landmarks", "clan_hall")).to include(
      "name" => "Clan Hall"
    )
  end

  it "gives each Central Square building an original-art silhouette inside the scene" do
    presentation = described_class.presentation("main")
    buildings = presentation.fetch("hotspots").except("go_forpost3", "go_forpost1")
      .merge(presentation.fetch("landmarks"))

    buildings.each_value do |geometry|
      expect(described_class.valid_polygon?(geometry.fetch("polygon"))).to be(true)
      x, y, width, height = geometry.fetch("box")
      expect(x + width).to be <= described_class::SCENE_WIDTH
      expect(y + height).to be <= described_class::SCENE_HEIGHT
    end
  end

  it "returns nil for null and unsupported keys" do
    expect(described_class.node(nil)).to be_nil
    expect(described_class.node("forpost99")).to be_nil
    expect(described_class.presentation(nil)).to be_nil
    expect(described_class.hotspot_presentation("main", nil)).to be_nil
    expect(described_class.hotspot_presentation("forpost99", "arena")).to be_nil
  end
end

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
    expect(described_class.hotspot_presentation("forpost4", "east_gate")).to include("polygon")
    expect(described_class.presentation("forpost4").fetch("landmarks")).not_to have_key("city_exit")
  end

  it "gives all five districts distinct complete artwork at the shared native scene size" do
    expect(described_class::SCENE_WIDTH).to eq(1250)
    expect(described_class::SCENE_HEIGHT).to eq(600)
    assets = described_class::PRESENTATIONS.values.map { |presentation| presentation.fetch("image_asset") }
    expect(assets.uniq.size).to eq(5)
    described_class::PRESENTATIONS.each_value do |presentation|
      expect(presentation).to include("image_size" => [1250, 600], "image_offset" => [0, 0])
      image_header = File.binread(Rails.root.join("app/assets/images", presentation.fetch("image_asset")), 24)
      expect(image_header[0, 8]).to eq("\x89PNG\r\n\x1a\n".b)
      expect(image_header[16, 8].unpack("NN")).to eq([1250, 600])
      expect(presentation.fetch("landmarks")).to be_present
    end
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
        expect(left + width).to be <= described_class::SCENE_WIDTH
        expect(top + height).to be <= described_class::SCENE_HEIGHT
      end
    end
  end

  it "keeps current Central Square and Residential Quarter geometry explicit" do
    expect(described_class.hotspot_presentation("main", "shop")).to include(
      "box" => [98, 245, 314, 225]
    )
    expect(described_class.hotspot_presentation("main", "go_forpost1")).to include(
      "box" => [933, 511, 76, 80],
      "direction" => "southeast"
    )
    expect(described_class.hotspot_presentation("forpost1", "go_main")).to include("direction" => "west")
  end

  it "gives every named building a bounded original-art silhouette inside its scene" do
    buildings = described_class::PRESENTATIONS.values.flat_map do |presentation|
      presentation.fetch("hotspots").reject { |key, _| key.start_with?("go_") }
        .merge(presentation.fetch("landmarks")).values
    end

    buildings.each do |geometry|
      expect(described_class.valid_polygon?(geometry.fetch("polygon"))).to be(true)
      x, y, width, height = geometry.fetch("box")
      expect(x).to be >= 12
      expect(y).to be >= 12
      expect(x + width).to be <= described_class::SCENE_WIDTH - 12
      expect(y + height).to be <= described_class::SCENE_HEIGHT - 40
    end
  end

  it "returns nil for null and unsupported keys" do
    expect(described_class.node(nil)).to be_nil
    expect(described_class.node("forpost99")).to be_nil
    expect(described_class.presentation(nil)).to be_nil
    expect(described_class.hotspot_presentation("main", nil)).to be_nil
    expect(described_class.hotspot_presentation("forpost99", "arena")).to be_nil
  end

  it "excludes the foreground Shop spire from the Guard Tower highlight" do
    tower = described_class.presentation("main").fetch("landmarks").fetch("guard_tower")
    shop = described_class.hotspot_presentation("main", "shop")
    expect(contains_scene_point?(tower, [244, 283])).to be(false)
    expect(contains_scene_point?(shop, [244, 283])).to be(true)
    expect(contains_scene_point?(tower, [145, 188])).to be(true)
  end

  def contains_scene_point?(geometry, point)
    left, top, width, height = geometry.fetch("box")
    vertices = geometry.fetch("polygon").map { |u, v| [left + width * u / 100.0, top + height * v / 100.0] }
    x, y = point
    vertices.each_index.count do |i|
      ax, ay = vertices[i]
      bx, by = vertices[(i + 1) % vertices.length]
      ((ay > y) != (by > y)) && x < ax + (y - ay) * (bx - ax) / (by - ay)
    end.odd?
  end
end

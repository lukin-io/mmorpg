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

  it "keeps only the outdoor gate whose destination cell was verified" do
    expect(described_class::GATES.keys).to eq(["west"])
    expect(described_class::GATES.fetch("west")).to include(
      "name" => "City Exit",
      "node_key" => "main",
      "local_coordinates" => [7, 0],
      "source_coordinates" => [1019, 1025]
    )
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
    expect(described_class.hotspot_presentation("main", "shop")).to eq(
      "box" => [96, 303, 320, 182]
    )
    expect(described_class.hotspot_presentation("main", "go_forpost1")).to include(
      "box" => [900, 496, 68, 104],
      "direction" => "southeast"
    )
    expect(described_class.presentation("forpost1").dig("landmarks", "clan_hall")).to include(
      "name" => "Clan Hall"
    )
  end

  it "returns nil for null and unsupported keys" do
    expect(described_class.node(nil)).to be_nil
    expect(described_class.node("forpost99")).to be_nil
    expect(described_class.presentation(nil)).to be_nil
    expect(described_class.hotspot_presentation("main", nil)).to be_nil
    expect(described_class.hotspot_presentation("forpost99", "arena")).to be_nil
  end
end

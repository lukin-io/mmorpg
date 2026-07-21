# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityCatalog do
  it "defines the complete nine-node source graph" do
    expect(described_class::NODES.keys).to contain_exactly(
      "city2_1", "city2_2", "city2_3", "city2_4", "city2_5",
      "city2_6", "city2_7", "city2_8", "city2_9"
    )

    described_class::NODES.each do |node_key, node|
      node["links"].each_key do |destination_key|
        expect(described_class.node(destination_key)).to be_present,
          "expected #{node_key} destination #{destination_key} to exist"
      end
    end


    expect(described_class::NODES.transform_values { |node| node["links"].keys }).to eq(
      "city2_1" => %w[city2_3 city2_2],
      "city2_2" => %w[city2_1 city2_4],
      "city2_3" => %w[city2_1 city2_4 city2_6],
      "city2_4" => %w[city2_2 city2_3 city2_5 city2_7],
      "city2_5" => %w[city2_4 city2_8],
      "city2_6" => %w[city2_3 city2_9 city2_7],
      "city2_7" => %w[city2_4 city2_6 city2_8],
      "city2_8" => %w[city2_5 city2_7],
      "city2_9" => %w[city2_6]
    )
  end

  it "keeps interactive and read-only features on their observed nodes" do
    expect(described_class::NODES.transform_values { |node| node["features"].keys }).to eq(
      "city2_1" => ["arena"],
      "city2_2" => %w[shop market junk_dealer numismatics airship_station],
      "city2_3" => ["hospital"],
      "city2_4" => [],
      "city2_5" => [],
      "city2_6" => [],
      "city2_7" => [],
      "city2_8" => [],
      "city2_9" => []
    )
  end

  it "defines West, South, and East gates with distinct nodes and source cells" do
    expect(described_class::GATES.transform_values { |gate| gate["node_key"] }).to eq(
      "west" => "city2_1",
      "south" => "city2_7",
      "east" => "city2_8"
    )
    expect(described_class::GATES.transform_values { |gate| gate["source_coordinates"] }).to eq(
      "west" => [1019, 1025],
      "south" => [1022, 1028],
      "east" => [1025, 1027]
    )
    expect(described_class::GATES.values.map { |gate| gate["local_coordinates"] }.uniq.size).to eq(3)
  end

  it "returns nil for null and unsupported node keys" do
    expect(described_class.node(nil)).to be_nil
    expect(described_class.node("city2_99")).to be_nil
  end

  it "defines image-map presentation geometry for every seeded city action" do
    described_class::NODES.each do |node_key, node|
      expected_hotspot_keys = node["links"].keys.map { |destination| "go_#{destination}" }
      expected_hotspot_keys.concat(node["features"].keys)
      described_class::GATES.each do |gate_key, gate|
        expected_hotspot_keys << "#{gate_key}_gate" if gate["node_key"] == node_key
      end

      presentation = described_class.presentation(node_key)

      expect(presentation).to include("image_position")
      expect(presentation.fetch("hotspots").keys).to contain_exactly(*expected_hotspot_keys)
      presentation.fetch("hotspots").each_value do |geometry|
        expect(geometry.key?("polygon") ^ geometry.key?("box")).to be(true)
      end
    end
  end

  it "keeps the observed central and trading interaction shapes explicit" do
    expect(described_class.hotspot_presentation("city2_1", "arena")).to include("polygon")
    expect(described_class.hotspot_presentation("city2_1", "west_gate")).to include(
      "marker" => [7, 57],
      "direction" => "west"
    )
    expect(described_class.hotspot_presentation("city2_2", "market")).to include("polygon")
  end

  it "returns nil for unsupported presentation keys" do
    expect(described_class.presentation(nil)).to be_nil
    expect(described_class.hotspot_presentation("city2_1", nil)).to be_nil
    expect(described_class.hotspot_presentation("city2_99", "arena")).to be_nil
  end
end

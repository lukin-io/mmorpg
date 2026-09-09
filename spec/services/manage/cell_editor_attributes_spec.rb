# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Guided cell editor attributes" do
  it "preserves source and result metadata when editing resource/action controls" do
    cell = build(:map_tile_template, metadata: {
      "local_actions" => [{"type" => "resource_search", "source_id" => "look", "message" => "Captured result"}],
      "resource_groups" => [{"key" => "herbs_7", "kind" => "herbs", "label" => "Group 7", "source_ref" => "atlas-group-7"}]
    })
    attributes = Manage::WorldCellAttributes.new(cell:, attributes: {
      "content_fields" => "1", "metadata" => {"source_map" => "captured"},
      "local_actions" => {"resource_search" => {"active" => "0", "label" => "Look"}},
      "resource_groups" => {"0" => {"key" => "herbs_7", "kind" => "herbs", "label" => "Herbs 7", "active" => "0"}}
    }).call

    expect(attributes.fetch("metadata")).to include("source_map" => "captured")
    expect(attributes.dig("metadata", "local_actions", 0)).to include("message" => "Captured result", "active" => false)
    expect(attributes.dig("metadata", "resource_groups", 0)).to include("source_ref" => "atlas-group-7", "active" => false)
  end

  it "preserves member metadata only while its selected NPC identity is unchanged" do
    npc = build(:tile_npc, metadata: {"encounter_rosters" => [{
      "key" => "mixed", "source_ref" => "captured",
      "members" => [{"npc_key" => "rat", "metadata" => {"captured_override" => true}}]
    }]})
    values = {
      "content_fields" => "1", "encounter_count" => "1", "metadata" => {},
      "rosters" => {"0" => {"key" => "mixed", "members" => {"0" => {"npc_key" => "rat", "level" => "4"}}}}
    }
    result = Manage::TileNpcAttributes.new(npc:, attributes: values).call
    expect(result.dig("metadata", "encounter_rosters", 0, "members", 0, "metadata")).to eq("captured_override" => true)
    expect(result.dig("metadata", "encounter_rosters", 0, "source_ref")).to eq("captured")

    values.dig("rosters", "0", "members", "0")["npc_key"] = "bandit"
    result = Manage::TileNpcAttributes.new(npc:, attributes: values).call
    expect(result.dig("metadata", "encounter_rosters", 0, "members", 0)).to eq("npc_key" => "bandit", "level" => 4)
  end
end

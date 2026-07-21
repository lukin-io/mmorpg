# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PerformLocalAction do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5) }

  subject(:result) do
    described_class.new(character:, tile:, local_action_type: "resource_search").call
  end

  it "completes the captured resource search without inventing an item reward" do
    expect(result.success).to be true
    expect(result.message).to include("search the surroundings")
    expect(result.interrupted_by).to be_nil
  end

  it "uses an authored source-backed result message when present" do
    tile.update!(
      metadata: tile.metadata.deep_merge(
        "local_actions" => [
          {
            "type" => "resource_search",
            "source_id" => "look",
            "result_message" => "Nothing was found."
          }
        ]
      )
    )

    expect(result.message).to eq("Nothing was found.")
  end

  it "hands the action off to a hostile NPC on the same cell" do
    npc = create(:tile_npc, zone: zone.name, x: 5, y: 5)

    expect(result.success).to be true
    expect(result.interrupted_by).to eq(npc)
    expect(result.message).to include("attacks before the action completes")
  end

  it "does not let a defeated hostile NPC interrupt the action" do
    create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5)

    expect(result.success).to be true
    expect(result.interrupted_by).to be_nil
  end

  it "rejects an inactive local action" do
    tile.update!(
      metadata: {
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "active" => false}
        ]
      }
    )

    expect(result.success).to be false
    expect(result.message).to include("no longer available")
  end

  it "rejects a tile outside the character's current position" do
    position.update!(x: 6)

    expect(result.success).to be false
    expect(result.message).to include("current cell")
  end

  it "rejects the action when the character has no persisted position" do
    position.destroy!

    expect(result.success).to be false
    expect(result.message).to include("current cell")
  end

  it "rejects a null action type" do
    null_result = described_class.new(character:, tile:, local_action_type: nil).call

    expect(null_result.success).to be false
  end

  it "rejects a captured action whose successful flow is still deferred" do
    fishing_tile = create(:map_tile_template, :with_fishing, zone: zone.name, x: 5, y: 5)

    fishing_result = described_class.new(
      character:,
      tile: fishing_tile,
      local_action_type: "fishing"
    ).call

    expect(fishing_result.success).to be false
    expect(fishing_result.message).to include("not implemented")
  end
end

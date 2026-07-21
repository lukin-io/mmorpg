# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::InterruptAction do
  let(:zone) { create(:zone, name: "Encounter Woods", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  subject(:result) { described_class.new(character:, return_context: "inventory").call }

  it "replaces an outdoor action with a same-cell hostile encounter" do
    npc = create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)

    expect(result).to be_interrupted
    expect(result.npc).to eq(npc)
    expect(result.match.arena_participations.npcs.count).to eq(2)
    expect(result.match.metadata["return_context"]).to eq("name" => "inventory")
  end

  it "does not interrupt without a source-backed hostile NPC" do
    expect(result).not_to be_interrupted
    expect(result.match).to be_nil
  end

  it "does not interrupt city actions" do
    zone.update!(location_type: "city")
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    expect(result).not_to be_interrupted
  end

  it "returns the active fight without creating another one" do
    npc = create(:tile_npc, zone: zone.name, x: 5, y: 5)
    active_match = Game::World::StartNpcFight.new(character:, tile_npc: npc).call

    expect { result }.not_to change(ArenaMatch, :count)
    expect(result).to be_interrupted
    expect(result.match).to eq(active_match)
  end

  it "ignores a defeated hostile encounter anchor" do
    create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5)

    expect(result).not_to be_interrupted
  end
end

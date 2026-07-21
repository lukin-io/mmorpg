# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::OutdoorNpcConfig do
  before do
    described_class.reload!
  end

  describe ".source_npc_for_tile" do
    it "returns the captured plague rat at its mapped local coordinate" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 7, 7)

      expect(npc[:key]).to eq("plague_rat")
      expect(npc[:name]).to eq("Plague Rat")
      expect(npc[:hp]).to eq(100)
      expect(npc[:damage]).to eq(7)
      expect(npc.dig(:metadata, :source_map)).to eq("m_1001_999")
      expect(npc.dig(:metadata, :source_coordinates)).to eq([1001, 999])
    end

    it "does not invent NPCs for other coordinates in the same zone" do
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 8, 7)).to be_nil
    end
  end
end

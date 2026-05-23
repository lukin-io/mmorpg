# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::OutdoorNpcConfig do
  before do
    described_class.reload!
  end

  describe ".source_npc_for_tile" do
    it "returns the captured plague rat only for the captured outdoor coordinate" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 1001, 999)

      expect(npc[:key]).to eq("plague_rat")
      expect(npc[:name]).to eq("Чумная крыса")
      expect(npc[:hp]).to eq(100)
      expect(npc[:damage]).to eq(7)
    end

    it "does not invent NPCs for other coordinates in the same zone" do
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 1002, 999)).to be_nil
    end
  end
end

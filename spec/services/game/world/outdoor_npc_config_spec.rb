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
      expect(npc.dig(:metadata, :encounter_count)).to eq(2)
    end

    it "keeps the uncaptured Plague Rat probability explicitly disabled" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 7, 7)
      loot_entry = npc.fetch(:loot).first

      expect(loot_entry[:chance]).to eq(0.0)
      expect(Game::LootEntry.new(loot_entry).chance_percent).to eq(0.0)
    end

    it "does not invent NPCs for other coordinates in the same zone" do
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 8, 7)).to be_nil
    end
  end

  describe ".config" do
    it "rejects a developer-authored loot entry without an explicit chance" do
      invalid_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [{key: "invalid", loot: [{kind: "item", item: "rat_tail"}]}]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(invalid_config)
      described_class.instance_variable_set(:@config, nil)

      expect { described_class.config }.to raise_error(
        described_class::InvalidConfigurationError,
        /NPC invalid loot entry 0: Loot chance is required/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end
  end
end

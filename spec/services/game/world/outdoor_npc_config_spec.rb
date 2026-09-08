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
      expect(npc.dig(:metadata, :encounter_experience_reward)).to eq(35)
      expect(npc.dig(:metadata, :combat_profile, :injected_attack_keys)).to eq(
        %w[spirit_arrow mind_blast]
      )
      expect(npc.dig(:metadata, :combat_profile, :injected_block_keys)).to eq(
        %w[magic_shield rainbow_barrier crystal_sphere]
      )
    end

    it "keeps the uncaptured Plague Rat probability explicitly disabled" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 7, 7)
      loot_entry = npc.fetch(:loot).first

      expect(loot_entry[:chance]).to eq(0.0)
      expect(Game::LootEntry.new(loot_entry).chance_percent).to eq(0.0)
    end

    it "does not invent NPCs for other coordinates in the same zone" do
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 9, 7)).to be_nil
    end

    it "preserves the four captured m_1008_1007 roster samples and timing windows" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 8, 7)
      rosters = npc.dig(:metadata, :encounter_rosters)

      expect(npc[:key]).to eq("wilderness_bandit")
      expect(npc.dig(:metadata, :source_map)).to eq("m_1008_1007")
      expect(npc.dig(:metadata, :passive_delay_windows)).to eq(
        [
          {key: "2026-09-01-interval-1", min_seconds: 230, max_seconds: 278},
          {key: "2026-09-01-interval-2", min_seconds: 127, max_seconds: 187}
        ]
      )
      expect(rosters.map { |sample| sample[:key] }).to eq(
        %w[2026-09-01-2334 2026-09-01-2340 2026-09-01-2345 2026-09-01-2351]
      )
      expect(rosters.map { |sample| sample[:members].size }).to eq([3, 1, 1, 2])
      expect(rosters.last[:members].pluck(:npc_key, :level, :hp)).to eq(
        [["wilderness_bandit", 8, 185], ["wilderness_robber", 9, 310]]
      )
      expect(described_class.find_npc("wilderness_robber")[:name]).to eq("Robber")
    end
  end

  describe ".config" do
    it "loads a ten-member authored roster and rejects an eleventh member on reload" do
      members = Array.new(10) { {npc_key: "capacity_spec"} }
      boundary_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [{key: "capacity_spec", metadata: {encounter_rosters: [{key: "boundary", members:}]}}]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(boundary_config)

      loaded = described_class.reload!
      expect(loaded.dig(:outpost, :npcs, 0, :metadata, :encounter_rosters, 0, :members).size).to eq(10)

      members << {npc_key: "capacity_spec"}
      expect { described_class.reload! }.to raise_error(
        described_class::InvalidConfigurationError, /roster 0 has invalid members/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

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


    it "rejects a captured roster that references an unknown template" do
      invalid_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [
            {
              key: "bandit",
              metadata: {
                encounter_rosters: [
                  {key: "bad", members: [{npc_key: "missing", level: 7, hp: 155}]}
                ]
              }
            }
          ]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(invalid_config)
      described_class.instance_variable_set(:@config, nil)

      expect { described_class.config }.to raise_error(
        described_class::InvalidConfigurationError,
        /references unknown template "missing"/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end
  end
end

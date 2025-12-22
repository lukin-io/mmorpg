# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ArenaNpcConfig do
  describe ".for_room" do
    it "returns NPCs for training room" do
      npcs = described_class.for_room("training")

      expect(npcs).not_to be_empty
      expect(npcs.all? { |n| n[:role] == "arena_bot" }).to be true
    end

    it "includes NPCs from other sections that list the room" do
      npcs = described_class.for_room("trial")

      # Should include some NPCs from training section that list trial
      npc_keys = npcs.map { |n| n[:key].to_s }
      expect(npc_keys).to include("arena_apprentice_warrior")
    end

    it "returns default NPCs for unknown rooms" do
      npcs = described_class.for_room("unknown_room")

      expect(npcs).not_to be_empty
    end
  end

  describe ".for_room_by_difficulty" do
    it "filters NPCs by easy difficulty" do
      npcs = described_class.for_room_by_difficulty("training", :easy)

      expect(npcs).not_to be_empty
      expect(npcs.all? { |n| n.dig(:metadata, :difficulty) == "easy" }).to be true
    end

    it "filters NPCs by medium difficulty" do
      npcs = described_class.for_room_by_difficulty("training", :medium)

      expect(npcs).not_to be_empty
      expect(npcs.all? { |n| n.dig(:metadata, :difficulty) == "medium" }).to be true
    end
  end

  describe ".sample_npc" do
    it "returns a random NPC for the room" do
      npc = described_class.sample_npc("training")

      expect(npc).to be_present
      expect(npc[:role]).to eq("arena_bot")
    end

    it "respects difficulty filter" do
      npc = described_class.sample_npc("training", difficulty: :easy)

      expect(npc).to be_present
      expect(npc.dig(:metadata, :difficulty)).to eq("easy")
    end

    it "is deterministic with seeded RNG" do
      rng1 = Random.new(42)
      rng2 = Random.new(42)

      npc1 = described_class.sample_npc("training", rng: rng1)
      npc2 = described_class.sample_npc("training", rng: rng2)

      expect(npc1[:key]).to eq(npc2[:key])
    end

    it "returns nil for room with no NPCs" do
      allow(described_class).to receive(:for_room).and_return([])

      npc = described_class.sample_npc("empty_room")

      expect(npc).to be_nil
    end
  end

  describe ".find_npc" do
    it "finds NPC by key" do
      npc = described_class.find_npc(:arena_training_dummy)

      expect(npc).to be_present
      expect(npc[:name]).to eq("Sparring Dummy")
    end

    it "returns nil for unknown key" do
      npc = described_class.find_npc(:unknown_npc)

      expect(npc).to be_nil
    end
  end

  describe ".has_npcs?" do
    it "returns true for rooms with NPCs" do
      expect(described_class.has_npcs?("training")).to be true
    end
  end

  describe ".extract_stats" do
    it "extracts stats from NPC config" do
      npc_config = {
        key: :test_npc,
        level: 5,
        hp: 100,
        damage: 15,
        metadata: {}
      }

      stats = described_class.extract_stats(npc_config)

      expect(stats[:hp]).to eq(100)
      expect(stats[:attack]).to eq(15)
      expect(stats[:defense]).to eq(13) # level * 2 + 3
      expect(stats[:agility]).to eq(10) # level + 5
    end

    it "uses metadata stats when present" do
      npc_config = {
        key: :test_npc,
        level: 5,
        metadata: {
          stats: {attack: 50, defense: 30, hp: 200}
        }
      }

      stats = described_class.extract_stats(npc_config)

      expect(stats[:attack]).to eq(50)
      expect(stats[:defense]).to eq(30)
      expect(stats[:hp]).to eq(200)
    end
  end

  describe ".difficulty_info" do
    it "returns difficulty descriptions" do
      info = described_class.difficulty_info

      expect(info[:easy][:emoji]).to eq("⭐")
      expect(info[:medium][:emoji]).to eq("⭐⭐")
      expect(info[:hard][:emoji]).to eq("⭐⭐⭐")
    end
  end

  describe ".all_npcs" do
    it "returns all unique NPCs" do
      npcs = described_class.all_npcs

      expect(npcs).not_to be_empty
      # Check uniqueness by key
      keys = npcs.map { |n| n[:key] }
      expect(keys.uniq.length).to eq(keys.length)
    end
  end
end

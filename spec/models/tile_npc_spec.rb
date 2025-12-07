# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileNpc, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "validations" do
    it "validates presence of required fields" do
      npc = TileNpc.new
      expect(npc).not_to be_valid
      expect(npc.errors[:zone]).to include("can't be blank")
      expect(npc.errors[:npc_key]).to include("can't be blank")
    end

    it "validates npc_role inclusion" do
      npc = build(:tile_npc, npc_role: "invalid")
      expect(npc).not_to be_valid
      expect(npc.errors[:npc_role]).to include("is not included in the list")
    end

    it "is valid with factory defaults" do
      npc = build(:tile_npc)
      expect(npc).to be_valid
    end
  end

  describe "scopes" do
    describe ".alive" do
      it "includes NPCs with no defeated_at" do
        alive = create(:tile_npc, defeated_at: nil)
        expect(TileNpc.alive).to include(alive)
      end

      it "excludes defeated NPCs" do
        defeated = create(:tile_npc, :defeated)
        expect(TileNpc.alive).not_to include(defeated)
      end
    end

    describe ".defeated" do
      it "includes NPCs with defeated_at" do
        defeated = create(:tile_npc, :defeated)
        expect(TileNpc.defeated).to include(defeated)
      end
    end

    describe ".hostile" do
      it "includes hostile NPCs" do
        hostile = create(:tile_npc, npc_role: "hostile")
        expect(TileNpc.hostile).to include(hostile)
      end

      it "excludes friendly NPCs" do
        friendly = create(:tile_npc, :friendly)
        expect(TileNpc.hostile).not_to include(friendly)
      end
    end

    describe ".at_tile" do
      it "finds NPC at specific coordinates" do
        npc = create(:tile_npc, zone: "Test Zone", x: 5, y: 10)
        found = TileNpc.at_tile("Test Zone", 5, 10)
        expect(found).to eq(npc)
      end

      it "returns nil when no NPC exists" do
        expect(TileNpc.find_by(zone: "Nowhere", x: 0, y: 0)).to be_nil
      end
    end
  end

  describe "#alive?" do
    it "returns true for non-defeated NPCs" do
      npc = build(:tile_npc, defeated_at: nil)
      expect(npc).to be_alive
    end

    it "returns false for defeated NPCs" do
      npc = build(:tile_npc, :defeated)
      expect(npc).not_to be_alive
    end
  end

  describe "#hostile?" do
    it "returns true for hostile role" do
      npc = build(:tile_npc, npc_role: "hostile")
      expect(npc).to be_hostile
    end

    it "returns false for friendly roles" do
      npc = build(:tile_npc, npc_role: "vendor")
      expect(npc).not_to be_hostile
    end
  end

  describe "#defeat!" do
    let(:character) { create(:character) }
    let(:npc) { create(:tile_npc) }

    it "sets defeated_at and defeated_by" do
      travel_to Time.zone.local(2025, 1, 15, 12, 0, 0) do
        npc.defeat!(character)
        expect(npc.defeated_at).to eq(Time.current)
        expect(npc.defeated_by).to eq(character)
      end
    end

    it "sets current_hp to 0" do
      npc.defeat!(character)
      expect(npc.current_hp).to eq(0)
    end

    it "sets respawns_at to ~30 minutes" do
      npc.defeat!(character)
      expect(npc.respawns_at).to be_present
      # Within range: 25-35 minutes (30 +/- 5 min variance)
      expect(npc.respawns_at).to be_between(25.minutes.from_now, 35.minutes.from_now)
    end

    it "returns false for already defeated NPCs" do
      npc = create(:tile_npc, :defeated)
      expect(npc.defeat!(character)).to be false
    end
  end

  describe "#respawn!" do
    let(:npc) { create(:tile_npc, :defeated, biome: "forest") }

    before do
      # Ensure BiomeNpcConfig is freshly loaded to avoid test order issues
      Game::World::BiomeNpcConfig.reload!
    end

    it "resets NPC with new random NPC from biome" do
      npc.respawn!
      npc.reload # Ensure we have fresh data from DB
      expect(npc.current_hp).to be > 0
      expect(npc.respawns_at).to be_nil
      expect(npc.defeated_at).to be_nil
      expect(npc.defeated_by).to be_nil
    end

    it "selects NPC appropriate for biome" do
      npc.respawn!
      npc.reload
      forest_npcs = Game::World::BiomeNpcConfig.npc_keys("forest").map(&:to_s)
      expect(forest_npcs).to include(npc.npc_key)
    end
  end

  describe "#time_until_respawn" do
    it "returns 0 for alive NPCs" do
      npc = build(:tile_npc)
      expect(npc.time_until_respawn).to eq(0)
    end

    it "returns seconds until respawn for defeated NPCs" do
      npc = build(:tile_npc, respawns_at: 10.minutes.from_now, defeated_at: 20.minutes.ago)
      expect(npc.time_until_respawn).to be_within(5).of(10.minutes.to_i)
    end
  end

  describe "#hp_percentage" do
    it "calculates correct percentage" do
      npc = build(:tile_npc, current_hp: 40, max_hp: 80)
      expect(npc.hp_percentage).to eq(50)
    end

    it "returns 100 when max_hp is zero" do
      npc = build(:tile_npc, current_hp: 0, max_hp: 0)
      expect(npc.hp_percentage).to eq(100)
    end
  end
end

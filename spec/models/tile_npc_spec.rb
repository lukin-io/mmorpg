# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileNpc, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "validations" do
    it "accepts hostile tile NPCs" do
      expect(build(:tile_npc, npc_role: "hostile")).to be_valid
    end

    it "rejects undocumented tile NPC roles" do
      npc = build(:tile_npc, npc_role: "town_service")

      expect(npc).not_to be_valid
      expect(npc.errors[:npc_role]).to include("is not included in the list")
    end
  end

  describe ".alive" do
    it "includes NPCs that are not defeated" do
      alive = create(:tile_npc, defeated_at: nil)

      expect(described_class.alive).to include(alive)
    end

    it "excludes defeated NPCs" do
      defeated = create(:tile_npc, :defeated)

      expect(described_class.alive).not_to include(defeated)
    end
  end

  describe "#hostile?" do
    it "is true for every documented tile NPC role" do
      expect(build(:tile_npc)).to be_hostile
    end
  end

  describe "#defeat!" do
    let(:character) { create(:character) }
    let(:npc) { create(:tile_npc) }

    it "marks the NPC defeated and schedules respawn state" do
      travel_to Time.zone.local(2026, 5, 21, 12, 0, 0) do
        expect(npc.defeat!(character)).to be true

        expect(npc.defeated_at).to eq(Time.current)
        expect(npc.defeated_by).to eq(character)
        expect(npc.current_hp).to eq(0)
        expect(npc.respawns_at).to be_between(25.minutes.from_now, 35.minutes.from_now)
      end
    end
  end
end

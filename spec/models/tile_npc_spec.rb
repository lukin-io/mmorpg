# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileNpc, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  before do
    %w[rat bandit robber].each { |key| create(:npc_template, npc_key: key) }
  end

  describe "validations" do
    it "accepts hostile tile NPCs" do
      expect(build(:tile_npc, npc_role: "hostile")).to be_valid
    end

    it "rejects undocumented tile NPC roles" do
      npc = build(:tile_npc, npc_role: "town_service")

      expect(npc).not_to be_valid
      expect(npc.errors[:npc_role]).to include("is not included in the list")
    end

    it "accepts the captured two-NPC encounter size" do
      expect(build(:tile_npc, :multi_npc_encounter)).to be_valid
    end

    it "accepts the explicit single-NPC encounter trait" do
      expect(build(:tile_npc, :single_npc_encounter)).to be_valid
    end

    it "accepts the source maximum of ten members for fixed counts and roster samples" do
      npc = build(:tile_npc, metadata: {
        "encounter_count" => 10,
        "encounter_rosters" => [
          {"key" => "capacity-boundary", "members" => Array.new(10) { {"npc_key" => "rat"} }}
        ]
      })

      expect(npc).to be_valid
      expect(npc.encounter_size).to eq(10)
    end

    it "rejects null, zero, and oversized encounter counts" do
      [nil, 0, 11].each do |count|
        npc = build(:tile_npc, metadata: {"encounter_count" => count})

        expect(npc).not_to be_valid
        expect(npc.errors[:metadata]).to include("encounter count must be between 1 and #{TileNpc::MAX_ENCOUNTER_SIZE}")
      end
    end

    it "accepts captured variable rosters and passive-delay windows" do
      npc = build(:tile_npc, metadata: {
        "encounter_rosters" => [
          {
            "key" => "mixed",
            "encounter_experience_reward" => 56,
            "trauma_percent" => 30,
            "members" => [
              {"npc_key" => "bandit", "level" => 8, "hp" => 185},
              {"npc_key" => "robber", "level" => 9, "hp" => 310}
            ]
          }
        ],
        "passive_delay_windows" => [
          {"key" => "observed", "min_seconds" => 127, "max_seconds" => 187}
        ]
      })

      expect(npc).to be_valid
    end

    it "rejects malformed, empty, duplicate-key, and oversized roster samples" do
      invalid_rosters = [
        nil,
        [],
        [{"key" => "empty", "members" => []}],
        [{"key" => "large", "members" => Array.new(11) { {"npc_key" => "rat"} }}],
        [
          {"key" => "duplicate", "members" => [{"npc_key" => "rat"}]},
          {"key" => "duplicate", "members" => [{"npc_key" => "rat"}]}
        ]
      ]

      invalid_rosters.each do |rosters|
        expect(build(:tile_npc, metadata: {"encounter_rosters" => rosters})).not_to be_valid
      end
    end

    it "rejects undocumented roster member values and invalid delay boundaries" do
      npc = build(:tile_npc, metadata: {
        "encounter_rosters" => [
          {
            "key" => "invalid",
            "encounter_experience_reward" => -1,
            "trauma_percent" => 101,
            "members" => [{"npc_key" => "", "level" => 0, "hp" => nil, "metadata" => "invalid"}]
          }
        ],
        "passive_delay_windows" => [
          {"min_seconds" => 200, "max_seconds" => 100}
        ]
      })

      expect(npc).not_to be_valid
      expect(npc.errors[:metadata]).to include(
        "encounter roster member npc_key is required",
        "level must be a positive integer",
        "hp must be a positive integer",
        "encounter roster member metadata must be an object",
        "encounter_experience_reward must be a non-negative integer",
        "trauma_percent must be between 0 and 100"
      )
      expect(npc.errors[:metadata]).to include(match(/passive delay window must have positive ordered bounds/))
    end
  end

  describe "#encounter_size" do
    it "defaults to one and returns the explicit source count" do
      expect(build(:tile_npc).encounter_size).to eq(1)
      expect(build(:tile_npc, :single_npc_encounter).encounter_size).to eq(1)
      expect(build(:tile_npc, :multi_npc_encounter).encounter_size).to eq(2)
    end
  end

  describe "captured encounter metadata" do
    it "returns only validated roster and timing arrays" do
      npc = build(:tile_npc, metadata: {
        "encounter_rosters" => [{"key" => "single", "members" => [{"npc_key" => "rat"}]}],
        "passive_delay_windows" => [{"min_seconds" => 10, "max_seconds" => 20}]
      })

      expect(npc.encounter_roster_samples.one?).to be true
      expect(npc.passive_delay_windows.one?).to be true
    end

    it "treats only a sampled roster anchor as a repeatable encounter source" do
      fixed = build(:tile_npc, :multi_npc_encounter)
      sampled = build(:tile_npc, metadata: {
        "encounter_rosters" => [
          {"key" => "single", "members" => [{"npc_key" => "rat"}]}
        ]
      })

      expect(fixed).not_to be_repeatable_encounter_source
      expect(sampled).to be_repeatable_encounter_source
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

    it "marks the NPC defeated without inventing a respawn timer" do
      travel_to Time.zone.local(2026, 5, 21, 12, 0, 0) do
        expect(npc.defeat!(character)).to be true

        expect(npc.defeated_at).to eq(Time.current)
        expect(npc.defeated_by).to eq(character)
        expect(npc.current_hp).to eq(0)
        expect(npc.respawns_at).to be_nil
      end
    end

    it "uses explicit source-backed respawn timing when present" do
      npc.npc_template.update!(metadata: {"respawn_seconds" => 7200, "respawn_variance_seconds" => 0})

      travel_to Time.zone.local(2026, 5, 21, 12, 0, 0) do
        expect(npc.defeat!(character)).to be true

        expect(npc.respawns_at).to eq(2.hours.from_now)
      end
    end
  end

  describe "#respawn!" do
    it "restores the same persisted placement without consulting runtime configuration" do
      npc = create(:tile_npc, :defeated, current_hp: 0, max_hp: 80)

      expect(npc.respawn!).to be true
      expect(npc.reload).to have_attributes(
        current_hp: 80,
        defeated_at: nil,
        defeated_by_id: nil,
        respawns_at: nil
      )
    end
  end
end

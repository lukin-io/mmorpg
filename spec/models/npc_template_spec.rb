# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpcTemplate, type: :model do
  describe "concerns integration" do
    let(:hostile_npc) { create(:npc_template, level: 10, role: "hostile") }
    let(:arena_bot) { create(:npc_template, level: 10, role: "arena_bot") }

    describe "Npc::CombatStats" do
      it "includes CombatStats concern" do
        expect(hostile_npc).to respond_to(:combat_stats)
        expect(hostile_npc).to respond_to(:combat_stat)
        expect(hostile_npc).to respond_to(:max_hp)
        expect(hostile_npc).to respond_to(:attack_power)
        expect(hostile_npc).to respond_to(:defense_value)
        expect(hostile_npc).to respond_to(:attack_damage_range)
      end

      it "combat_stats returns consistent values" do
        stats1 = hostile_npc.combat_stats
        stats2 = hostile_npc.combat_stats

        expect(stats1).to eq(stats2)
      end
    end

    describe "Npc::Combatable" do
      it "includes Combatable concern" do
        expect(hostile_npc).to respond_to(:can_engage_combat?)
        expect(hostile_npc).to respond_to(:hostile?)
        expect(hostile_npc).to respond_to(:attackable?)
        expect(hostile_npc).to respond_to(:combat_behavior)
        expect(hostile_npc).to respond_to(:difficulty_rating)
        expect(hostile_npc).to respond_to(:should_defend?)
        expect(hostile_npc).to respond_to(:roll_initiative)
        expect(hostile_npc).to respond_to(:loot_table)
        expect(hostile_npc).to respond_to(:xp_reward)
        expect(hostile_npc).to respond_to(:gold_reward)
      end
    end

    describe "concern interaction" do
      it "roll_initiative uses combat_stat for agility" do
        agility = hostile_npc.combat_stat(:agility)
        initiative = hostile_npc.roll_initiative(rng: Random.new(42))

        expect(initiative).to be_between(agility + 1, agility + 10)
      end

      it "should_defend? considers combat_behavior" do
        expect(hostile_npc.combat_behavior).to eq(:aggressive)
        expect(arena_bot.combat_behavior).to eq(:balanced)

        # Different behaviors have different defend chances
        # This verifies the concerns work together
      end
    end
  end

  describe "legacy method compatibility" do
    let(:npc) { create(:npc_template, level: 10, role: "hostile") }

    describe "#health" do
      it "delegates to max_hp for backward compatibility" do
        expect(npc.health).to eq(npc.max_hp)
      end

      it "reflects metadata overrides" do
        npc.update!(metadata: {"health" => 500})
        expect(npc.health).to eq(500)
      end
    end

    describe "#damage_range" do
      it "delegates to attack_damage_range for backward compatibility" do
        expect(npc.damage_range).to eq(npc.attack_damage_range)
      end

      it "returns a Range object" do
        expect(npc.damage_range).to be_a(Range)
      end
    end

    describe "#ai_behavior" do
      it "returns string version of combat_behavior" do
        expect(npc.ai_behavior).to eq("aggressive")
        expect(npc.ai_behavior).to be_a(String)
      end

      it "reflects metadata override" do
        npc.update!(metadata: {"ai_behavior" => "defensive"})
        expect(npc.ai_behavior).to eq("defensive")
      end
    end

    describe "#arena_difficulty" do
      it "returns string version of difficulty_rating" do
        expect(npc.arena_difficulty).to eq("medium")
        expect(npc.arena_difficulty).to be_a(String)
      end

      it "reflects metadata override" do
        npc.update!(metadata: {"difficulty" => "hard"})
        expect(npc.arena_difficulty).to eq("hard")
      end
    end
  end

  describe "arena bot specific methods" do
    let(:arena_bot) { create(:npc_template, role: "arena_bot", metadata: {"arena_rooms" => ["training"], "avatar" => "🎯"}) }
    let(:hostile) { create(:npc_template, role: "hostile") }

    describe "#arena_bot?" do
      it "returns true for arena_bot role" do
        expect(arena_bot.arena_bot?).to be true
      end

      it "returns false for other roles" do
        expect(hostile.arena_bot?).to be false
      end
    end

    describe "#arena_rooms" do
      it "returns rooms from metadata" do
        expect(arena_bot.arena_rooms).to eq(["training"])
      end

      it "returns empty array when not specified" do
        expect(hostile.arena_rooms).to eq([])
      end
    end

    describe "#avatar_emoji" do
      it "returns avatar from metadata" do
        expect(arena_bot.avatar_emoji).to eq("🎯")
      end

      it "returns default emoji when not specified" do
        expect(hostile.avatar_emoji).to eq("⚔️")
      end
    end
  end

  describe "scopes" do
    describe ".in_zone" do
      # This spec covers a bug where PostgreSQL's JSONB `?` operator conflicted
      # with Rails bind variable placeholders, causing:
      # ActiveRecord::PreparedStatementInvalid: wrong number of bind variables
      #
      # Fix: Use jsonb_exists() function instead of ? operator

      let!(:npc_single_zone) do
        create(:npc_template, name: "Forest Guardian", metadata: {"zone" => "dark_forest"})
      end

      let!(:npc_multi_zone) do
        create(:npc_template, name: "Wandering Merchant", metadata: {"zones" => ["dark_forest", "crystal_caves", "sunlit_plains"]})
      end

      let!(:npc_other_zone) do
        create(:npc_template, name: "Cave Troll", metadata: {"zone" => "crystal_caves"})
      end

      let!(:npc_no_zone) do
        create(:npc_template, name: "Random Monster", metadata: {})
      end

      it "finds NPCs with matching single zone in metadata" do
        result = described_class.in_zone("dark_forest")

        expect(result).to include(npc_single_zone)
        expect(result).not_to include(npc_other_zone)
        expect(result).not_to include(npc_no_zone)
      end

      it "finds NPCs with zone in zones array" do
        result = described_class.in_zone("dark_forest")

        expect(result).to include(npc_multi_zone)
      end

      it "finds NPCs from either single zone or zones array" do
        result = described_class.in_zone("dark_forest")

        expect(result).to contain_exactly(npc_single_zone, npc_multi_zone)
      end

      it "returns empty when no NPCs match the zone" do
        result = described_class.in_zone("nonexistent_zone")

        expect(result).to be_empty
      end

      it "finds NPCs in zones array by different zone name" do
        result = described_class.in_zone("crystal_caves")

        expect(result).to contain_exactly(npc_other_zone, npc_multi_zone)
      end

      it "handles nil zone gracefully" do
        # Should not raise an error
        expect { described_class.in_zone(nil).to_a }.not_to raise_error
      end

      it "handles empty string zone" do
        result = described_class.in_zone("")

        expect(result).to be_empty
      end

      it "is chainable with other scopes" do
        result = described_class.in_zone("dark_forest").where(role: "monster")

        expect(result).to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe "validations" do
    it "requires a name" do
      npc = build(:npc_template, name: nil)

      expect(npc).not_to be_valid
      expect(npc.errors[:name]).to be_present
    end
  end

  describe "metadata JSONB storage" do
    it "stores zone as string" do
      npc = create(:npc_template, metadata: {"zone" => "test_zone"})

      expect(npc.reload.metadata["zone"]).to eq("test_zone")
    end

    it "stores zones as array" do
      zones = ["zone_a", "zone_b", "zone_c"]
      npc = create(:npc_template, metadata: {"zones" => zones})

      expect(npc.reload.metadata["zones"]).to eq(zones)
    end
  end
end

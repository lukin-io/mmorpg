# frozen_string_literal: true

require "rails_helper"

RSpec.describe Npc::CombatStats do
  let(:npc_template) { create(:npc_template, level: 10, role: "hostile") }

  describe "#combat_stats" do
    context "with default formula calculations" do
      it "calculates stats based on level" do
        stats = npc_template.combat_stats

        expect(stats[:attack]).to eq(10 * 3 + 5) # 35
        expect(stats[:defense]).to eq(10 * 2 + 3) # 23
        expect(stats[:agility]).to eq(10 + 5) # 15
        expect(stats[:hp]).to eq(10 * 10 + 20) # 120
        expect(stats[:crit_chance]).to eq(10)
        expect(stats[:dodge_chance]).to eq(5) # level / 2 capped at 25
      end

      it "returns HashWithIndifferentAccess for symbol/string access" do
        stats = npc_template.combat_stats

        expect(stats[:attack]).to eq(stats["attack"])
        expect(stats[:hp]).to eq(stats["hp"])
      end
    end

    context "with metadata stats override" do
      before do
        npc_template.update!(metadata: {
          "stats" => {
            "attack" => 100,
            "defense" => 50,
            "hp" => 500
          }
        })
      end

      it "uses explicit metadata stats" do
        stats = npc_template.combat_stats

        expect(stats[:attack]).to eq(100)
        expect(stats[:defense]).to eq(50)
        expect(stats[:hp]).to eq(500)
      end

      it "fills missing stats with formula defaults" do
        stats = npc_template.combat_stats

        # agility not in metadata, should use formula
        expect(stats[:agility]).to eq(10 + 5)
      end
    end

    context "with individual metadata fields" do
      before do
        npc_template.update!(metadata: {
          "base_damage" => 25,
          "health" => 200
        })
      end

      it "builds stats from individual fields" do
        stats = npc_template.combat_stats

        expect(stats[:attack]).to eq(25)
        expect(stats[:hp]).to eq(200)
        # Defense should still use formula since not specified
        expect(stats[:defense]).to eq(10 * 2 + 3)
      end
    end

    context "with alternative metadata field names" do
      it "recognizes 'damage' as attack" do
        npc_template.update!(metadata: {"damage" => 30})
        expect(npc_template.combat_stats[:attack]).to eq(30)
      end

      it "recognizes 'hp' as health" do
        npc_template.update!(metadata: {"hp" => 150})
        expect(npc_template.combat_stats[:hp]).to eq(150)
      end

      it "recognizes 'base_defense' as defense" do
        npc_template.update!(metadata: {"base_defense" => 15})
        expect(npc_template.combat_stats[:defense]).to eq(15)
      end

      it "recognizes 'base_agility' as agility" do
        npc_template.update!(metadata: {"base_agility" => 20})
        expect(npc_template.combat_stats[:agility]).to eq(20)
      end
    end

    context "with role modifiers" do
      it "applies arena_bot modifier (0.9 attack/defense, 0.95 hp)" do
        arena_bot = create(:npc_template, level: 10, role: "arena_bot")
        stats = arena_bot.combat_stats

        # Base: attack = 35, defense = 23, hp = 120
        # With arena_bot modifiers: attack = 31, defense = 20, hp = 114
        expect(stats[:attack]).to eq(31)
        expect(stats[:defense]).to eq(20)
        expect(stats[:hp]).to eq(114)
      end

      it "applies guard modifier (1.2 attack, 1.5 defense, 1.3 hp)" do
        guard = create(:npc_template, level: 10, role: "guard")
        stats = guard.combat_stats

        # Base: attack = 35, defense = 23, hp = 120
        # With guard modifiers: attack = 42, defense = 34, hp = 156
        expect(stats[:attack]).to eq(42)
        expect(stats[:defense]).to eq(34)
        expect(stats[:hp]).to eq(156)
      end

      it "applies trainer modifier (1.1 attack/defense)" do
        trainer = create(:npc_template, level: 10, role: "trainer")
        stats = trainer.combat_stats

        expect(stats[:attack]).to eq(38) # 35 * 1.1
        expect(stats[:defense]).to eq(25) # 23 * 1.1
      end

      it "applies vendor modifier (0.3 attack/defense, 0.5 hp)" do
        vendor = create(:npc_template, level: 10, role: "vendor")
        stats = vendor.combat_stats

        expect(stats[:attack]).to eq(10) # 35 * 0.3
        expect(stats[:defense]).to eq(6) # 23 * 0.3
        expect(stats[:hp]).to eq(60) # 120 * 0.5
      end

      it "applies quest_giver modifier (0.5 attack/defense, 0.8 hp)" do
        quest_giver = create(:npc_template, level: 10, role: "quest_giver")
        stats = quest_giver.combat_stats

        expect(stats[:attack]).to eq(17) # 35 * 0.5
        expect(stats[:defense]).to eq(11) # 23 * 0.5
        expect(stats[:hp]).to eq(96) # 120 * 0.8
      end

      it "defaults to hostile modifier for unknown roles" do
        # Hostile has 1.0 modifiers (no change)
        expect(npc_template.combat_stats[:attack]).to eq(35)
        expect(npc_template.combat_stats[:defense]).to eq(23)
      end
    end

    context "with level override" do
      it "recalculates stats with override level" do
        stats = npc_template.combat_stats(override_level: 5)

        expect(stats[:attack]).to eq(5 * 3 + 5) # 20
        expect(stats[:hp]).to eq(5 * 10 + 20) # 70
      end

      it "still applies role modifiers with override level" do
        arena_bot = create(:npc_template, level: 10, role: "arena_bot")
        stats = arena_bot.combat_stats(override_level: 5)

        # Base at level 5: attack = 20
        # With arena_bot modifier: 20 * 0.9 = 18
        expect(stats[:attack]).to eq(18)
      end
    end

    context "with nil and edge case values" do
      # Note: Database has NOT NULL constraint on metadata, so we test with empty hash
      it "handles empty metadata hash (treated as nil)" do
        npc_template.update!(metadata: {})
        stats = npc_template.combat_stats

        expect(stats[:attack]).to eq(35)
        expect(stats[:hp]).to eq(120)
      end

      it "handles level 1 (minimum)" do
        level_1_npc = create(:npc_template, level: 1, role: "hostile")
        stats = level_1_npc.combat_stats

        expect(stats[:attack]).to eq(1 * 3 + 5) # 8
        expect(stats[:defense]).to eq(1 * 2 + 3) # 5
        expect(stats[:hp]).to eq(1 * 10 + 20) # 30
        expect(stats[:dodge_chance]).to eq(0) # 1 / 2 = 0
      end

      it "handles very high level (100)" do
        high_level = create(:npc_template, level: 100, role: "hostile")
        stats = high_level.combat_stats

        expect(stats[:attack]).to eq(100 * 3 + 5) # 305
        expect(stats[:defense]).to eq(100 * 2 + 3) # 203
        expect(stats[:hp]).to eq(100 * 10 + 20) # 1020
        expect(stats[:dodge_chance]).to eq(25) # capped at 25
      end

      it "handles zero values in metadata" do
        npc_template.update!(metadata: {"base_damage" => 0, "health" => 0})
        stats = npc_template.combat_stats

        # Zero is a valid override
        expect(stats[:attack]).to eq(0)
        expect(stats[:hp]).to eq(0)
      end
    end
  end

  describe "#combat_stat" do
    it "returns a single stat value" do
      expect(npc_template.combat_stat(:attack)).to eq(35)
      expect(npc_template.combat_stat(:hp)).to eq(120)
    end

    it "returns 0 for unknown stats" do
      expect(npc_template.combat_stat(:unknown)).to eq(0)
      expect(npc_template.combat_stat(:mana)).to eq(0)
    end

    it "accepts string stat names" do
      expect(npc_template.combat_stat("attack")).to eq(35)
    end

    it "supports level override" do
      expect(npc_template.combat_stat(:attack, override_level: 5)).to eq(20)
    end
  end

  describe "#max_hp" do
    it "returns HP from combat stats" do
      expect(npc_template.max_hp).to eq(120)
    end

    it "reflects role modifiers" do
      arena_bot = create(:npc_template, level: 10, role: "arena_bot")
      expect(arena_bot.max_hp).to eq(114) # 120 * 0.95
    end

    it "reflects metadata overrides" do
      npc_template.update!(metadata: {"health" => 500})
      expect(npc_template.max_hp).to eq(500)
    end
  end

  describe "#attack_power" do
    it "returns attack from combat stats" do
      expect(npc_template.attack_power).to eq(35)
    end

    it "reflects role modifiers" do
      guard = create(:npc_template, level: 10, role: "guard")
      expect(guard.attack_power).to eq(42) # 35 * 1.2
    end
  end

  describe "#defense_value" do
    it "returns defense from combat stats" do
      expect(npc_template.defense_value).to eq(23)
    end

    it "reflects role modifiers" do
      guard = create(:npc_template, level: 10, role: "guard")
      expect(guard.defense_value).to eq(34) # 23 * 1.5
    end
  end

  describe "#attack_damage_range" do
    it "returns a range based on attack power" do
      range = npc_template.attack_damage_range
      attack = npc_template.attack_power # 35
      variance = attack / 4 # 8

      expect(range).to eq((attack - variance)..(attack + variance))
    end

    it "ensures minimum variance of 1" do
      weak_npc = create(:npc_template, level: 1, role: "vendor")
      range = weak_npc.attack_damage_range
      attack = weak_npc.attack_power # 2 (8 * 0.3)

      # variance = max(2/4, 1) = 1
      expect(range).to eq((attack - 1)..(attack + 1))
    end

    it "returns Range object" do
      expect(npc_template.attack_damage_range).to be_a(Range)
    end
  end

  describe "consistency across combat systems" do
    let(:arena_bot) { create(:npc_template, level: 5, role: "arena_bot") }
    let(:hostile_npc) { create(:npc_template, level: 5, role: "hostile") }

    it "arena bots are consistently weaker than hostile NPCs" do
      arena_stats = arena_bot.combat_stats
      hostile_stats = hostile_npc.combat_stats

      expect(arena_stats[:attack]).to be < hostile_stats[:attack]
      expect(arena_stats[:defense]).to be < hostile_stats[:defense]
      expect(arena_stats[:hp]).to be < hostile_stats[:hp]
    end

    it "same level NPCs have comparable but modified stats" do
      arena_attack = arena_bot.combat_stats[:attack]
      hostile_attack = hostile_npc.combat_stats[:attack]

      # Arena bot should be 90% of hostile
      expect(arena_attack.to_f / hostile_attack).to be_within(0.01).of(0.9)
    end
  end
end

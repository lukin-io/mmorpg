# frozen_string_literal: true

require "rails_helper"

RSpec.describe Npc::Combatable do
  let(:hostile_npc) { create(:npc_template, role: "hostile", level: 10) }
  let(:arena_bot) { create(:npc_template, role: "arena_bot", level: 10) }
  let(:vendor) { create(:npc_template, role: "vendor", level: 5) }

  describe "#can_engage_combat?" do
    context "with combat roles" do
      it "returns true for hostile" do
        expect(hostile_npc.can_engage_combat?).to be true
      end

      it "returns true for arena_bot" do
        expect(arena_bot.can_engage_combat?).to be true
      end

      it "returns true for guard" do
        guard = create(:npc_template, role: "guard")
        expect(guard.can_engage_combat?).to be true
      end

      it "returns true for trainer" do
        trainer = create(:npc_template, role: "trainer")
        expect(trainer.can_engage_combat?).to be true
      end
    end

    context "with non-combat roles" do
      it "returns false for vendor" do
        expect(vendor.can_engage_combat?).to be false
      end

      it "returns false for quest_giver" do
        quest_giver = create(:npc_template, role: "quest_giver")
        expect(quest_giver.can_engage_combat?).to be false
      end

      it "returns false for innkeeper" do
        innkeeper = create(:npc_template, role: "innkeeper")
        expect(innkeeper.can_engage_combat?).to be false
      end

      it "returns false for banker" do
        banker = create(:npc_template, role: "banker")
        expect(banker.can_engage_combat?).to be false
      end

      it "returns false for auctioneer" do
        auctioneer = create(:npc_template, role: "auctioneer")
        expect(auctioneer.can_engage_combat?).to be false
      end

      it "returns false for crafter" do
        crafter = create(:npc_template, role: "crafter")
        expect(crafter.can_engage_combat?).to be false
      end

      it "returns false for lore" do
        lore = create(:npc_template, role: "lore")
        expect(lore.can_engage_combat?).to be false
      end
    end
  end

  describe "#hostile?" do
    it "returns true for hostile role" do
      expect(hostile_npc.hostile?).to be true
    end

    it "returns false for all other roles" do
      expect(arena_bot.hostile?).to be false
      expect(vendor.hostile?).to be false
      expect(create(:npc_template, role: "guard").hostile?).to be false
      expect(create(:npc_template, role: "trainer").hostile?).to be false
    end
  end

  describe "#attackable?" do
    it "returns same as can_engage_combat?" do
      expect(hostile_npc.attackable?).to eq(hostile_npc.can_engage_combat?)
      expect(vendor.attackable?).to eq(vendor.can_engage_combat?)
      expect(arena_bot.attackable?).to eq(arena_bot.can_engage_combat?)
    end

    it "is true for combat-capable NPCs" do
      expect(hostile_npc.attackable?).to be true
      expect(arena_bot.attackable?).to be true
    end

    it "is false for non-combat NPCs" do
      expect(vendor.attackable?).to be false
    end
  end

  describe "#combat_behavior" do
    context "with default role behaviors" do
      it "returns :aggressive for hostile" do
        expect(hostile_npc.combat_behavior).to eq(:aggressive)
      end

      it "returns :balanced for arena_bot" do
        expect(arena_bot.combat_behavior).to eq(:balanced)
      end

      it "returns :defensive for guard" do
        guard = create(:npc_template, role: "guard")
        expect(guard.combat_behavior).to eq(:defensive)
      end

      it "returns :defensive for trainer" do
        trainer = create(:npc_template, role: "trainer")
        expect(trainer.combat_behavior).to eq(:defensive)
      end

      it "returns :passive for non-combat roles" do
        expect(vendor.combat_behavior).to eq(:passive)
        expect(create(:npc_template, role: "quest_giver").combat_behavior).to eq(:passive)
        expect(create(:npc_template, role: "innkeeper").combat_behavior).to eq(:passive)
      end
    end

    context "with metadata override" do
      it "uses ai_behavior from metadata" do
        hostile_npc.update!(metadata: {"ai_behavior" => "defensive"})
        expect(hostile_npc.combat_behavior).to eq(:defensive)
      end

      it "uses behavior from metadata as alternative key" do
        hostile_npc.update!(metadata: {"behavior" => "balanced"})
        expect(hostile_npc.combat_behavior).to eq(:balanced)
      end

      it "prefers ai_behavior over behavior when both present" do
        hostile_npc.update!(metadata: {"ai_behavior" => "aggressive", "behavior" => "defensive"})
        expect(hostile_npc.combat_behavior).to eq(:aggressive)
      end

      it "ignores invalid behavior values" do
        hostile_npc.update!(metadata: {"ai_behavior" => "invalid_behavior"})
        # Falls back to role default
        expect(hostile_npc.combat_behavior).to eq(:aggressive)
      end
    end

    context "with empty metadata" do
      # Note: Database has NOT NULL constraint, so we test with empty hash
      it "falls back to role default with empty metadata" do
        hostile_npc.update!(metadata: {})
        expect(hostile_npc.combat_behavior).to eq(:aggressive)
      end
    end
  end

  describe "#difficulty_rating" do
    context "with metadata value" do
      it "returns rating from metadata if present" do
        hostile_npc.update!(metadata: {"difficulty" => "hard"})
        expect(hostile_npc.difficulty_rating).to eq(:hard)
      end

      it "uses rarity as alternative key" do
        hostile_npc.update!(metadata: {"rarity" => "elite"})
        expect(hostile_npc.difficulty_rating).to eq(:elite)
      end

      it "prefers difficulty over rarity" do
        hostile_npc.update!(metadata: {"difficulty" => "easy", "rarity" => "boss"})
        expect(hostile_npc.difficulty_rating).to eq(:easy)
      end
    end

    context "with level-based calculation" do
      it "returns :easy for levels 1-5" do
        expect(create(:npc_template, level: 1).difficulty_rating).to eq(:easy)
        expect(create(:npc_template, level: 3).difficulty_rating).to eq(:easy)
        expect(create(:npc_template, level: 5).difficulty_rating).to eq(:easy)
      end

      it "returns :medium for levels 6-15" do
        expect(create(:npc_template, level: 6).difficulty_rating).to eq(:medium)
        expect(create(:npc_template, level: 10).difficulty_rating).to eq(:medium)
        expect(create(:npc_template, level: 15).difficulty_rating).to eq(:medium)
      end

      it "returns :hard for levels 16-30" do
        expect(create(:npc_template, level: 16).difficulty_rating).to eq(:hard)
        expect(create(:npc_template, level: 25).difficulty_rating).to eq(:hard)
        expect(create(:npc_template, level: 30).difficulty_rating).to eq(:hard)
      end

      it "returns :elite for levels 31-50" do
        expect(create(:npc_template, level: 31).difficulty_rating).to eq(:elite)
        expect(create(:npc_template, level: 40).difficulty_rating).to eq(:elite)
        expect(create(:npc_template, level: 50).difficulty_rating).to eq(:elite)
      end

      it "returns :boss for levels 51+" do
        expect(create(:npc_template, level: 51).difficulty_rating).to eq(:boss)
        expect(create(:npc_template, level: 60).difficulty_rating).to eq(:boss)
        expect(create(:npc_template, level: 100).difficulty_rating).to eq(:boss)
      end
    end
  end

  describe "#can_flee?" do
    context "with role restrictions" do
      it "returns false for arena_bot (training bots don't flee)" do
        expect(arena_bot.can_flee?).to be false
      end

      it "returns false for guard (guards stand their ground)" do
        guard = create(:npc_template, role: "guard")
        expect(guard.can_flee?).to be false
      end

      it "returns true for hostile by default" do
        expect(hostile_npc.can_flee?).to be true
      end

      it "returns true for trainer (can forfeit sparring)" do
        trainer = create(:npc_template, role: "trainer")
        expect(trainer.can_flee?).to be true
      end
    end

    context "with metadata override" do
      it "can be disabled via metadata" do
        hostile_npc.update!(metadata: {"can_flee" => false})
        expect(hostile_npc.can_flee?).to be false
      end

      it "remains false for restricted roles even with metadata" do
        # Role restriction takes precedence
        arena_bot.update!(metadata: {"can_flee" => true})
        expect(arena_bot.can_flee?).to be false
      end
    end
  end

  describe "#flee_threshold" do
    it "returns 0.15 by default" do
      expect(hostile_npc.flee_threshold).to eq(0.15)
    end

    it "reads from metadata" do
      hostile_npc.update!(metadata: {"flee_threshold" => 0.25})
      expect(hostile_npc.flee_threshold).to eq(0.25)
    end

    it "handles empty metadata" do
      hostile_npc.update!(metadata: {})
      expect(hostile_npc.flee_threshold).to eq(0.15)
    end

    it "converts string to float" do
      hostile_npc.update!(metadata: {"flee_threshold" => "0.3"})
      expect(hostile_npc.flee_threshold).to eq(0.3)
    end
  end

  describe "#loot_table" do
    it "returns empty array by default" do
      expect(hostile_npc.loot_table).to eq([])
    end

    it "returns loot_table from metadata" do
      loot = [{"item_key" => "sword", "chance" => 0.1}]
      hostile_npc.update!(metadata: {"loot_table" => loot})
      expect(hostile_npc.loot_table).to eq(loot)
    end

    it "supports alternative 'loot' key" do
      loot = [{"item_key" => "potion", "chance" => 0.5}]
      hostile_npc.update!(metadata: {"loot" => loot})
      expect(hostile_npc.loot_table).to eq(loot)
    end

    it "handles empty metadata" do
      hostile_npc.update!(metadata: {})
      expect(hostile_npc.loot_table).to eq([])
    end
  end

  describe "#xp_reward" do
    it "calculates from level by default (level * 10)" do
      expect(hostile_npc.xp_reward).to eq(100) # level 10 * 10
    end

    it "uses metadata if present" do
      hostile_npc.update!(metadata: {"xp_reward" => 250})
      expect(hostile_npc.xp_reward).to eq(250)
    end

    it "supports alternative 'xp' key" do
      hostile_npc.update!(metadata: {"xp" => 300})
      expect(hostile_npc.xp_reward).to eq(300)
    end

    it "handles empty metadata" do
      hostile_npc.update!(metadata: {})
      expect(hostile_npc.xp_reward).to eq(100)
    end

    it "scales with level" do
      expect(create(:npc_template, level: 1).xp_reward).to eq(10)
      expect(create(:npc_template, level: 50).xp_reward).to eq(500)
    end
  end

  describe "#gold_reward" do
    it "calculates from level by default (level * 2 + 5)" do
      expect(hostile_npc.gold_reward).to eq(25) # 10 * 2 + 5
    end

    it "uses metadata if present" do
      hostile_npc.update!(metadata: {"gold_reward" => 100})
      expect(hostile_npc.gold_reward).to eq(100)
    end

    it "supports alternative 'gold' key" do
      hostile_npc.update!(metadata: {"gold" => 150})
      expect(hostile_npc.gold_reward).to eq(150)
    end

    it "handles empty metadata" do
      hostile_npc.update!(metadata: {})
      expect(hostile_npc.gold_reward).to eq(25)
    end

    it "scales with level" do
      expect(create(:npc_template, level: 1).gold_reward).to eq(7) # 1*2+5
      expect(create(:npc_template, level: 50).gold_reward).to eq(105) # 50*2+5
    end
  end

  describe "#roll_initiative" do
    it "returns agility plus random value (1-10)" do
      rng = Random.new(42)
      initiative = hostile_npc.roll_initiative(rng: rng)

      expect(initiative).to be_between(
        hostile_npc.combat_stat(:agility) + 1,
        hostile_npc.combat_stat(:agility) + 10
      )
    end

    it "is deterministic with seeded RNG" do
      init1 = hostile_npc.roll_initiative(rng: Random.new(123))
      init2 = hostile_npc.roll_initiative(rng: Random.new(123))

      expect(init1).to eq(init2)
    end

    it "varies with different seeds" do
      init1 = hostile_npc.roll_initiative(rng: Random.new(1))
      init2 = hostile_npc.roll_initiative(rng: Random.new(2))

      # Very likely to be different (not guaranteed but extremely probable)
      expect(init1).not_to eq(init2)
    end

    it "uses default RNG when not provided" do
      initiative = hostile_npc.roll_initiative

      expect(initiative).to be >= hostile_npc.combat_stat(:agility) + 1
      expect(initiative).to be <= hostile_npc.combat_stat(:agility) + 10
    end
  end

  describe "#should_defend?" do
    context "with defensive behavior" do
      before do
        hostile_npc.update!(metadata: {"ai_behavior" => "defensive"})
      end

      it "has 40% chance to defend below 70% HP" do
        rng = Random.new(1)
        # Verify behavior is defensive
        expect(hostile_npc.combat_behavior).to eq(:defensive)

        # Run multiple times to verify it considers defending
        results = (1..100).map do |seed|
          hostile_npc.should_defend?(current_hp_ratio: 0.5, rng: Random.new(seed))
        end

        # Should have some true and some false results
        expect(results).to include(true)
        expect(results).to include(false)
      end

      it "never defends at full HP" do
        # At 100% HP, defensive NPCs don't meet the threshold
        result = hostile_npc.should_defend?(current_hp_ratio: 1.0, rng: Random.new(1))
        expect(result).to be false
      end
    end

    context "with balanced behavior" do
      before { arena_bot } # arena_bot has balanced behavior

      it "has 20% chance to defend below 40% HP" do
        expect(arena_bot.combat_behavior).to eq(:balanced)

        results = (1..100).map do |seed|
          arena_bot.should_defend?(current_hp_ratio: 0.3, rng: Random.new(seed))
        end

        # Should have some true results but fewer than defensive
        expect(results).to include(true)
      end

      it "doesn't defend above 40% HP" do
        result = arena_bot.should_defend?(current_hp_ratio: 0.5, rng: Random.new(1))
        expect(result).to be false
      end
    end

    context "with aggressive behavior" do
      it "has only 10% chance to defend below 20% HP" do
        expect(hostile_npc.combat_behavior).to eq(:aggressive)

        # At 15% HP with aggressive behavior
        results = (1..100).map do |seed|
          hostile_npc.should_defend?(current_hp_ratio: 0.15, rng: Random.new(seed))
        end

        # Should rarely defend
        true_count = results.count(true)
        expect(true_count).to be < 20 # Very few defends
      end

      it "never defends above 20% HP" do
        result = hostile_npc.should_defend?(current_hp_ratio: 0.25, rng: Random.new(1))
        expect(result).to be false
      end
    end

    context "with passive behavior" do
      it "almost always defends" do
        expect(vendor.combat_behavior).to eq(:passive)

        results = (1..100).map do |seed|
          vendor.should_defend?(current_hp_ratio: 0.5, rng: Random.new(seed))
        end

        # Should mostly defend (80% chance at any HP)
        true_count = results.count(true)
        expect(true_count).to be > 60
      end
    end

    context "edge cases" do
      it "handles 0% HP ratio" do
        result = hostile_npc.should_defend?(current_hp_ratio: 0.0, rng: Random.new(1))
        expect([true, false]).to include(result)
      end

      it "handles negative HP ratio" do
        result = hostile_npc.should_defend?(current_hp_ratio: -0.1, rng: Random.new(1))
        expect([true, false]).to include(result)
      end

      it "handles HP ratio > 1" do
        result = hostile_npc.should_defend?(current_hp_ratio: 1.5, rng: Random.new(1))
        expect(result).to be false
      end
    end
  end

  describe "integration with CombatStats" do
    it "uses combat_stat for initiative roll" do
      # Verify the concerns work together
      agility = hostile_npc.combat_stat(:agility)
      initiative = hostile_npc.roll_initiative(rng: Random.new(42))

      expect(initiative).to be > agility
      expect(initiative).to be <= agility + 10
    end
  end
end

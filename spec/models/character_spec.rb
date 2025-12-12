require "rails_helper"

RSpec.describe Character, type: :model do
  describe "inheritance" do
    it "inherits guild and clan membership from the owner" do
      user = create(:user)
      guild = create(:guild, leader: user)
      clan = create(:clan, leader: user)
      create(:guild_membership, guild: guild, user: user, status: :active)
      create(:clan_membership, clan: clan, user: user)

      character = create(:character, user: user)

      expect(character.guild).to eq(user.primary_guild)
      expect(character.clan).to eq(user.primary_clan)
    end
  end

  describe "limits" do
    it "prevents creating more than the allowed number of characters" do
      user = create(:user)
      User::MAX_CHARACTERS.times { create(:character, user: user) }

      extra_character = build(:character, user: user)

      expect(extra_character).not_to be_valid
      expect(extra_character.errors[:base]).to include("character limit reached")
    end
  end

  describe "alignment tiers" do
    let(:character) { create(:character) }

    describe "#alignment_tier" do
      it "returns celestial for high positive score" do
        character.update!(alignment_score: 900)
        expect(character.alignment_tier).to eq(:celestial)
      end

      it "returns neutral for scores near zero" do
        character.update!(alignment_score: 0)
        expect(character.alignment_tier).to eq(:neutral)
      end

      it "returns absolute_darkness for very low score" do
        character.update!(alignment_score: -900)
        expect(character.alignment_tier).to eq(:absolute_darkness)
      end

      it "returns true_light for high-mid positive score" do
        character.update!(alignment_score: 600)
        expect(character.alignment_tier).to eq(:true_light)
      end

      it "returns child_of_darkness for mid-range negative score" do
        character.update!(alignment_score: -300)
        expect(character.alignment_tier).to eq(:child_of_darkness)
      end
    end

    describe "#alignment_emoji" do
      it "returns angel emoji for celestial tier" do
        character.update!(alignment_score: 900)
        expect(character.alignment_emoji).to eq("👼")
      end

      it "returns yin-yang for neutral tier" do
        character.update!(alignment_score: 0)
        expect(character.alignment_emoji).to eq("☯️")
      end

      it "returns black heart for absolute darkness" do
        character.update!(alignment_score: -900)
        expect(character.alignment_emoji).to eq("🖤")
      end
    end

    describe "#adjust_alignment!" do
      it "increases alignment score" do
        character.update!(alignment_score: 0)
        character.adjust_alignment!(100)
        expect(character.alignment_score).to eq(100)
      end

      it "clamps to maximum of 1000" do
        character.update!(alignment_score: 950)
        character.adjust_alignment!(100)
        expect(character.alignment_score).to eq(1000)
      end

      it "clamps to minimum of -1000" do
        character.update!(alignment_score: -950)
        character.adjust_alignment!(-100)
        expect(character.alignment_score).to eq(-1000)
      end
    end
  end

  describe "chaos tiers" do
    let(:character) { create(:character, chaos_score: 0) }

    describe "#chaos_tier" do
      it "returns lawful for low score" do
        expect(character.chaos_tier).to eq(:lawful)
      end

      it "returns absolute_chaos for high score" do
        character.update!(chaos_score: 900)
        expect(character.chaos_tier).to eq(:absolute_chaos)
      end

      it "returns chaotic for mid-high score" do
        character.update!(chaos_score: 600)
        expect(character.chaos_tier).to eq(:chaotic)
      end
    end

    describe "#chaos_emoji" do
      it "returns scales for lawful" do
        expect(character.chaos_emoji).to eq("⚖️")
      end

      it "returns explosion for absolute chaos" do
        character.update!(chaos_score: 900)
        expect(character.chaos_emoji).to eq("💥")
      end
    end

    describe "#adjust_chaos!" do
      it "increases chaos score" do
        character.adjust_chaos!(50)
        expect(character.chaos_score).to eq(50)
      end

      it "clamps to maximum of 1000" do
        character.update!(chaos_score: 980)
        character.adjust_chaos!(50)
        expect(character.chaos_score).to eq(1000)
      end

      it "clamps to minimum of 0" do
        character.update!(chaos_score: 10)
        character.adjust_chaos!(-50)
        expect(character.chaos_score).to eq(0)
      end
    end
  end

  describe "faction display" do
    let(:character) { create(:character) }

    describe "#faction_emoji" do
      it "returns shield for alliance" do
        character.update!(faction_alignment: "alliance")
        expect(character.faction_emoji).to eq("🛡️")
      end

      it "returns sword for rebellion" do
        character.update!(faction_alignment: "rebellion")
        expect(character.faction_emoji).to eq("⚔️")
      end

      it "returns flag for neutral" do
        character.update!(faction_alignment: "neutral")
        expect(character.faction_emoji).to eq("🏳️")
      end
    end

    describe "#alignment_display" do
      it "combines faction and tier information" do
        character.update!(faction_alignment: "alliance", alignment_score: 600)
        display = character.alignment_display
        expect(display).to include("🛡️")  # faction
        expect(display).to include("✨")   # true light
        expect(display).to include("True Light")
      end
    end
  end

  describe "#max_action_points" do
    let(:character_class) { create(:character_class, base_stats: {strength: 5, vitality: 5, agility: 8, intellect: 3}) }
    let(:character) { create(:character, character_class: character_class, level: 10) }

    it "calculates AP based on level and agility" do
      # Formula: 50 (base) + (level * 3) + (agility * 2)
      # = 50 + (10 * 3) + (8 * 2)
      # = 50 + 30 + 16 = 96
      expect(character.max_action_points).to eq(96)
    end

    it "increases AP with higher level" do
      character.update!(level: 20)
      # = 50 + (20 * 3) + (8 * 2)
      # = 50 + 60 + 16 = 126
      expect(character.max_action_points).to eq(126)
    end

    it "increases AP with allocated agility" do
      character.update!(allocated_stats: {"agility" => 5})
      # Base agility: 8, Allocated: 5, Total: 13
      # = 50 + (10 * 3) + (13 * 2)
      # = 50 + 30 + 26 = 106
      expect(character.max_action_points).to eq(106)
    end

    it "returns appropriate AP for level 1 character" do
      low_class = create(:character_class, base_stats: {strength: 5, vitality: 5, agility: 5, intellect: 5})
      low_char = create(:character, level: 1, character_class: low_class)
      # = 50 + (1 * 3) + (5 * 2) = 50 + 3 + 10 = 63
      expect(low_char.max_action_points).to eq(63)
    end
  end

  # ============================================
  # Passive Skills
  # ============================================
  describe "passive skills" do
    let(:character) { create(:character, passive_skills: {}) }

    describe "#passive_skill_level" do
      it "returns 0 for unset skill" do
        expect(character.passive_skill_level(:wanderer)).to eq(0)
      end

      it "returns the skill level when set" do
        character.update!(passive_skills: { "wanderer" => 50 })
        expect(character.passive_skill_level(:wanderer)).to eq(50)
      end

      it "handles string keys" do
        character.update!(passive_skills: { "wanderer" => 25 })
        expect(character.passive_skill_level("wanderer")).to eq(25)
      end

      it "handles symbol keys" do
        character.update!(passive_skills: { "wanderer" => 75 })
        expect(character.passive_skill_level(:wanderer)).to eq(75)
      end

      it "returns 0 for nil value" do
        character.update!(passive_skills: { "wanderer" => nil })
        expect(character.passive_skill_level(:wanderer)).to eq(0)
      end
    end

    describe "#set_passive_skill!" do
      it "sets a skill level" do
        character.set_passive_skill!(:wanderer, 30)
        expect(character.passive_skill_level(:wanderer)).to eq(30)
      end

      it "persists to database" do
        character.set_passive_skill!(:wanderer, 40)
        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(40)
      end

      it "clamps to max level" do
        character.set_passive_skill!(:wanderer, 150)
        expect(character.passive_skill_level(:wanderer)).to eq(100)
      end

      it "clamps negative values to 0" do
        character.set_passive_skill!(:wanderer, -10)
        expect(character.passive_skill_level(:wanderer)).to eq(0)
      end

      it "updates existing skill level" do
        character.set_passive_skill!(:wanderer, 20)
        character.set_passive_skill!(:wanderer, 60)
        expect(character.passive_skill_level(:wanderer)).to eq(60)
      end

      it "handles string keys" do
        character.set_passive_skill!("wanderer", 45)
        expect(character.passive_skill_level(:wanderer)).to eq(45)
      end
    end

    describe "#increase_passive_skill!" do
      it "increases skill by 1 by default" do
        character.set_passive_skill!(:wanderer, 10)
        character.increase_passive_skill!(:wanderer)
        expect(character.passive_skill_level(:wanderer)).to eq(11)
      end

      it "increases skill by specified amount" do
        character.set_passive_skill!(:wanderer, 10)
        character.increase_passive_skill!(:wanderer, 5)
        expect(character.passive_skill_level(:wanderer)).to eq(15)
      end

      it "clamps at max level" do
        character.set_passive_skill!(:wanderer, 98)
        character.increase_passive_skill!(:wanderer, 10)
        expect(character.passive_skill_level(:wanderer)).to eq(100)
      end

      it "starts from 0 for unset skill" do
        character.increase_passive_skill!(:wanderer, 5)
        expect(character.passive_skill_level(:wanderer)).to eq(5)
      end
    end

    describe "#passive_skill_calculator" do
      it "returns a PassiveSkillCalculator instance" do
        expect(character.passive_skill_calculator).to be_a(Game::Skills::PassiveSkillCalculator)
      end

      it "caches the calculator" do
        calc1 = character.passive_skill_calculator
        calc2 = character.passive_skill_calculator
        expect(calc1).to equal(calc2)
      end
    end

    describe "#clear_passive_skill_cache!" do
      it "clears the cached calculator" do
        calc1 = character.passive_skill_calculator
        character.clear_passive_skill_cache!
        calc2 = character.passive_skill_calculator
        expect(calc1).not_to equal(calc2)
      end
    end

    describe "integration with calculator" do
      it "calculates movement cooldown based on wanderer skill" do
        character.set_passive_skill!(:wanderer, 0)
        cooldown_at_0 = character.passive_skill_calculator.apply_movement_cooldown(10)

        character.set_passive_skill!(:wanderer, 100)
        character.clear_passive_skill_cache!
        cooldown_at_100 = character.passive_skill_calculator.apply_movement_cooldown(10)

        expect(cooldown_at_0).to eq(10) # No reduction at level 0
        expect(cooldown_at_100).to eq(3) # 70% reduction at level 100
      end

      it "provides smooth scaling between levels" do
        character.set_passive_skill!(:wanderer, 50)
        cooldown = character.passive_skill_calculator.apply_movement_cooldown(10)

        # At level 50: 35% reduction -> 10 * 0.65 = 6.5
        expect(cooldown).to eq(6.5)
      end
    end
  end

  # ============================================
  # Stats Allocation
  # ============================================
  describe "stats allocation" do
    let(:character_class) { create(:character_class, base_stats: { "strength" => 10, "dexterity" => 10 }) }
    let(:character) { create(:character, character_class: character_class, allocated_stats: {}) }

    describe "#stats" do
      it "returns StatBlock with base stats" do
        stats = character.stats
        expect(stats.get(:strength)).to eq(10)
        expect(stats.get(:dexterity)).to eq(10)
      end

      it "includes allocated stats" do
        character.update!(allocated_stats: { "strength" => 5 })
        stats = character.stats
        expect(stats.get(:strength)).to eq(15) # 10 base + 5 allocated
      end

      it "handles multiple allocations" do
        character.update!(allocated_stats: { "strength" => 3, "dexterity" => 2 })
        stats = character.stats
        expect(stats.get(:strength)).to eq(13)
        expect(stats.get(:dexterity)).to eq(12)
      end

      it "handles nil character class" do
        character.update!(character_class: nil)
        stats = character.stats
        expect(stats).to be_a(Game::Systems::StatBlock)
      end

      it "adds allocated stats to missing base stats" do
        character.update!(allocated_stats: { "luck" => 5 })
        stats = character.stats
        expect(stats.get(:luck)).to eq(5)
      end
    end
  end
end

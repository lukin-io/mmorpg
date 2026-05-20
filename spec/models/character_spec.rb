require "rails_helper"

RSpec.describe Character, type: :model do
  describe "inheritance" do
    it "inherits clan membership from the owner" do
      user = create(:user)
      clan = create(:clan, leader: user)
      create(:clan_membership, clan: clan, user: user)

      character = create(:character, user: user)

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
      it "returns label for celestial tier" do
        character.update!(alignment_score: 900)
        expect(character.alignment_emoji).to eq("Celestial")
      end

      it "returns label for neutral tier" do
        character.update!(alignment_score: 0)
        expect(character.alignment_emoji).to eq("Neutral")
      end

      it "returns label for absolute darkness" do
        character.update!(alignment_score: -900)
        expect(character.alignment_emoji).to eq("Absolute Darkness")
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
      it "returns label for lawful" do
        expect(character.chaos_emoji).to eq("Lawful")
      end

      it "returns label for absolute chaos" do
        character.update!(chaos_score: 900)
        expect(character.chaos_emoji).to eq("Absolute Chaos")
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
      it "returns label for alliance" do
        character.update!(faction_alignment: "alliance")
        expect(character.faction_emoji).to eq("Alliance")
      end

      it "returns label for rebellion" do
        character.update!(faction_alignment: "rebellion")
        expect(character.faction_emoji).to eq("Rebellion")
      end

      it "returns label for neutral" do
        character.update!(faction_alignment: "neutral")
        expect(character.faction_emoji).to eq("Neutral")
      end
    end

    describe "#alignment_display" do
      it "combines faction and tier information" do
        character.update!(faction_alignment: "alliance", alignment_score: 600)
        display = character.alignment_display
        expect(display).to include("Alliance")
        expect(display).to include("True Light")
      end
    end
  end

  describe "#max_action_points" do
    let(:character) { create(:character, level: 10) }

    it "calculates AP based on level and dexterity" do
      # Formula: 50 (base) + (level * 3) + (dexterity * 2)
      # = 50 + (10 * 3) + (1 * 2)
      expect(character.max_action_points).to eq(82)
    end

    it "increases AP with higher level" do
      character.update!(level: 20)
      expect(character.max_action_points).to eq(112)
    end

    it "increases AP with allocated dexterity" do
      character.update!(allocated_stats: {"dexterity" => 5})
      expect(character.max_action_points).to eq(92)
    end

    it "returns appropriate AP for level 1 character" do
      low_char = create(:character, level: 1)
      expect(low_char.max_action_points).to eq(55)
    end
  end

  describe "combat power formulas" do
    let(:character) do
      create(:character, level: 3, allocated_stats: {
        "strength" => 9, "dexterity" => 7, "vitality" => 11, "luck" => 4
      })
    end

    it "includes level in attack power and defense" do
      expect(character.attack_power).to eq(25) # 20 strength + 4 dexterity + 1 level
      expect(character.defense).to eq(16) # 12 vitality + 3 strength + 1 level
    end

    it "includes equipped item bonuses in the combat breakdown" do
      sword = create(:item_template, item_type: "equipment", slot: "main_hand", stat_modifiers: {"attack" => 7})
      armor = create(:item_template, item_type: "equipment", slot: "chest", stat_modifiers: {"defense" => 5})
      create(:inventory_item, inventory: character.inventory, item_template: sword, equipped: true)
      create(:inventory_item, inventory: character.inventory, item_template: armor, equipped: true)

      breakdown = character.combat_power_breakdown

      expect(breakdown[:attack_power][:equipment]).to eq(7)
      expect(breakdown[:attack_power][:total]).to eq(32)
      expect(breakdown[:defense][:equipment]).to eq(6)
      expect(breakdown[:defense][:total]).to eq(22)
    end

    it "applies equipped primary stat and vitality effects" do
      ring = create(:item_template, item_type: "equipment", slot: "ring_1",
        stat_modifiers: {"strength" => 3, "hp" => 20})
      create(:inventory_item, inventory: character.inventory, item_template: ring, equipped: true)

      expect(character.stats.get(:strength)).to eq(13)
      expect(character.attack_power).to eq(31)
      expect(character.effective_max_hp).to eq(character.read_attribute(:max_hp) + 20)
    end
  end

  # ============================================
  # Abilities
  # ============================================
  describe "abilities" do
    let(:character) { create(:character, passive_skills: {}) }

    describe "#passive_skill_level" do
      it "returns 0 for unset skill" do
        expect(character.passive_skill_level(:wanderer)).to eq(0)
      end

      it "returns the skill level when set" do
        character.update!(passive_skills: {"wanderer" => 50})
        expect(character.passive_skill_level(:wanderer)).to eq(50)
      end

      it "handles string keys" do
        character.update!(passive_skills: {"wanderer" => 25})
        expect(character.passive_skill_level("wanderer")).to eq(25)
      end

      it "handles symbol keys" do
        character.update!(passive_skills: {"wanderer" => 75})
        expect(character.passive_skill_level(:wanderer)).to eq(75)
      end

      it "returns 0 for nil value" do
        character.update!(passive_skills: {"wanderer" => nil})
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
    let(:character) { create(:character, allocated_stats: {}) }

    describe "#stats" do
      it "returns StatBlock with Neverlands starter base stats" do
        stats = character.stats
        expect(stats.get(:strength)).to eq(1)
        expect(stats.get(:dexterity)).to eq(1)
        expect(stats.get(:luck)).to eq(1)
        expect(stats.get(:vitality)).to eq(1)
        expect(stats.get(:intelligence)).to eq(1)
      end

      it "includes allocated stats" do
        character.update!(allocated_stats: {"strength" => 5})
        stats = character.stats
        expect(stats.get(:strength)).to eq(6)
      end

      it "handles multiple allocations" do
        character.update!(allocated_stats: {"strength" => 3, "dexterity" => 2})
        stats = character.stats
        expect(stats.get(:strength)).to eq(4)
        expect(stats.get(:dexterity)).to eq(3)
      end

      it "normalizes legacy stat aliases into canonical primary stats" do
        character.update!(allocated_stats: {"agility" => 5, "intellect" => 4, "constitution" => 3})
        stats = character.stats
        expect(stats.get(:dexterity)).to eq(6)
        expect(stats.get(:intelligence)).to eq(5)
        expect(stats.get(:vitality)).to eq(4)
      end
    end
  end

  # ============================================
  # Bug Fix: Missing Arena Associations
  # ============================================
  # Regression tests for missing arena_applications and arena_participations
  # associations that caused NoMethodError in ArenaController#index.
  #
  # Bug: undefined method 'arena_applications' for an instance of Character
  # Fix: Added has_many :arena_applications and :arena_participations associations

  describe "arena associations" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user) }

    describe "arena_applications" do
      it "responds to arena_applications" do
        expect(character).to respond_to(:arena_applications)
      end

      it "returns an empty collection when no applications exist" do
        expect(character.arena_applications).to be_empty
      end

      it "returns arena applications for the character" do
        arena_room = create(:arena_room)
        application = create(:arena_application, applicant: character, arena_room: arena_room)

        expect(character.arena_applications).to include(application)
      end

      it "supports the active scope" do
        arena_room = create(:arena_room)
        active_app = create(:arena_application, applicant: character, arena_room: arena_room, status: :open)
        expired_app = create(:arena_application, applicant: character, arena_room: arena_room, status: :expired)

        expect(character.arena_applications.active).to include(active_app)
        expect(character.arena_applications.active).not_to include(expired_app)
      end

      it "destroys arena_applications when character is destroyed" do
        arena_room = create(:arena_room)
        application = create(:arena_application, applicant: character, arena_room: arena_room)
        application_id = application.id

        character.destroy

        expect(ArenaApplication.find_by(id: application_id)).to be_nil
      end
    end

    describe "arena_participations" do
      it "responds to arena_participations" do
        expect(character).to respond_to(:arena_participations)
      end

      it "returns an empty collection when no participations exist" do
        expect(character.arena_participations).to be_empty
      end

      it "returns arena participations for the character" do
        arena_match = create(:arena_match)
        participation = create(:arena_participation, character: character, arena_match: arena_match, user: user)

        expect(character.arena_participations).to include(participation)
      end

      it "supports includes with arena_match" do
        # Regression test: ArenaController uses this query pattern
        # @recent_matches = current_character.arena_participations
        #   .includes(:arena_match)
        #   .order(created_at: :desc)
        expect {
          character.arena_participations.includes(:arena_match).order(created_at: :desc).to_a
        }.not_to raise_error
      end

      it "destroys arena_participations when character is destroyed" do
        arena_match = create(:arena_match)
        participation = create(:arena_participation, character: character, arena_match: arena_match, user: user)
        participation_id = participation.id

        character.destroy

        expect(ArenaParticipation.find_by(id: participation_id)).to be_nil
      end
    end

    describe "arena_applications with active query" do
      # Regression test: ArenaController#index calls current_character.arena_applications.active.first
      it "returns the first active application" do
        arena_room = create(:arena_room)
        create(:arena_application, applicant: character, arena_room: arena_room, status: :open)

        result = character.arena_applications.active.first
        expect(result).to be_an(ArenaApplication)
        expect(result.status).to eq("open")
      end

      it "returns nil when no active applications exist" do
        expect(character.arena_applications.active.first).to be_nil
      end
    end
  end

  # ============================================
  # Avatar Assignment
  # ============================================
  describe "avatar" do
    describe "AVATARS constant" do
      it "contains all available player avatars" do
        expect(Character::AVATARS).to contain_exactly(
          "dwarven", "nightveil", "lightbearer", "pathfinder", "arcanist", "ironbound"
        )
      end

      it "is frozen" do
        expect(Character::AVATARS).to be_frozen
      end
    end

    describe "automatic avatar assignment on create" do
      it "assigns a random avatar on character creation" do
        user = create(:user)
        character = create(:character, user: user)

        expect(character.avatar).to be_present
        expect(Character::AVATARS).to include(character.avatar)
      end

      it "does not override explicitly set avatar" do
        user = create(:user)
        character = create(:character, user: user, avatar: "nightveil")

        expect(character.avatar).to eq("nightveil")
      end

      it "assigns different avatars randomly (statistical test)" do
        # Create multiple users to avoid character limit
        avatars = 10.times.map do
          user = create(:user)
          create(:character, user: user).avatar
        end

        # With 6 avatars and 10 characters, we should see at least 2 different avatars
        expect(avatars.uniq.size).to be > 1
      end
    end

    describe "#avatar_image_path" do
      it "returns the full asset path for the avatar" do
        user = create(:user)
        character = create(:character, user: user, avatar: "dwarven")

        expect(character.avatar_image_path).to eq("avatars/dwarven.png")
      end

      it "returns fallback path when avatar is nil" do
        user = create(:user)
        character = build(:character, user: user, avatar: nil)
        # Skip validation to test nil avatar case
        character.save!(validate: false)
        character.update_column(:avatar, nil)
        character.reload

        expect(character.avatar_image_path).to eq("avatars/dwarven.png")
      end
    end
  end
end

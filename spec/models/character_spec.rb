require "rails_helper"

RSpec.describe Character, type: :model do
  describe "limits" do
    it "prevents creating more than the allowed number of characters" do
      user = create(:user)
      User::MAX_CHARACTERS.times { create(:character, user: user) }

      extra_character = build(:character, user: user)

      expect(extra_character).not_to be_valid
      expect(extra_character.errors[:base]).to include("character limit reached")
    end
  end

  describe "Neverlands alignment marker" do
    let(:character) { create(:character) }

    it "defaults to no alignment" do
      expect(character.alignment).to eq("none")
      expect(character.alignment_label).to eq("Нет")
    end

    it "uses source-backed alignment labels" do
      character.update!(alignment: "light")

      expect(character.alignment_display).to eq("Свет")
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
      expect(breakdown[:defense][:equipment]).to eq(5)
      expect(breakdown[:defense][:total]).to eq(21)
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

      it "ignores uncaptured stat aliases" do
        character.update!(allocated_stats: {"agility" => 5, "intellect" => 4, "constitution" => 3})
        stats = character.stats
        expect(stats.get(:dexterity)).to eq(1)
        expect(stats.get(:intelligence)).to eq(1)
        expect(stats.get(:vitality)).to eq(1)
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
end

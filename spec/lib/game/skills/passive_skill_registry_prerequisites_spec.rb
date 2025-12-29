# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillRegistry, "prerequisites" do
  # Mock character for testing
  def mock_character(skills = {})
    obj = Object.new
    skills_hash = skills.transform_keys(&:to_s)

    obj.define_singleton_method(:passive_skill_level) do |skill|
      skills_hash[skill.to_s].to_i
    end

    obj.define_singleton_method(:base_passive_skill_level) do |skill|
      skills_hash[skill.to_s].to_i
    end

    obj.define_singleton_method(:available_skill_points_for_pool) do |pool|
      (pool == :combat) ? 5 : 3
    end

    obj.define_singleton_method(:respond_to?) do |method, include_all = false|
      %i[passive_skill_level base_passive_skill_level available_skill_points_for_pool].include?(method) ||
        super(method, include_all)
    end

    obj
  end

  describe ".prerequisites" do
    it "returns nil for skills without prerequisites" do
      expect(described_class.prerequisites(:melee_combat)).to be_nil
    end

    it "returns hash for AND prerequisites" do
      prereqs = described_class.prerequisites(:block_mastery)
      expect(prereqs).to eq({evasion: 20})
    end

    it "returns array for OR prerequisites" do
      prereqs = described_class.prerequisites(:critical_strikes)
      expect(prereqs).to be_an(Array)
      expect(prereqs).to include({melee_combat: 30})
      expect(prereqs).to include({ranged_combat: 30})
    end
  end

  describe ".prerequisites_met?" do
    context "with AND prerequisites (hash)" do
      let(:skill) { :block_mastery }  # Requires evasion: 20

      it "returns met: true when prerequisite is satisfied" do
        char = mock_character(evasion: 25)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
        expect(result[:missing]).to be_empty
      end

      it "returns met: false when prerequisite is not satisfied" do
        char = mock_character(evasion: 10)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be false
        expect(result[:missing]).to include(
          hash_including(skill: :evasion, required: 20, current: 10)
        )
      end

      it "returns met: true when exactly at required level" do
        char = mock_character(evasion: 20)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
      end
    end

    context "with OR prerequisites (array)" do
      let(:skill) { :critical_strikes }  # Requires melee_combat: 30 OR ranged_combat: 30

      it "returns met: true when first option is satisfied" do
        char = mock_character(melee_combat: 35, ranged_combat: 0)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
      end

      it "returns met: true when second option is satisfied" do
        char = mock_character(melee_combat: 0, ranged_combat: 40)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
      end

      it "returns met: true when both options are satisfied" do
        char = mock_character(melee_combat: 50, ranged_combat: 50)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
      end

      it "returns met: false when neither option is satisfied" do
        char = mock_character(melee_combat: 20, ranged_combat: 10)
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be false
        expect(result[:missing].any? { |m| m[:is_or_condition] }).to be true
      end
    end

    context "with no prerequisites" do
      let(:skill) { :melee_combat }

      it "returns met: true for any character" do
        char = mock_character({})
        result = described_class.prerequisites_met?(skill, char)

        expect(result[:met]).to be true
        expect(result[:missing]).to be_empty
      end
    end
  end

  describe ".can_spend?" do
    it "returns allowed: true when all conditions met" do
      char = mock_character(evasion: 25)
      result = described_class.can_spend?(:block_mastery, char)

      expect(result[:allowed]).to be true
    end

    it "returns allowed: false when prerequisites not met" do
      char = mock_character(evasion: 10)
      result = described_class.can_spend?(:block_mastery, char)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("Requires")
    end

    it "returns allowed: false for invalid skill" do
      char = mock_character({})
      result = described_class.can_spend?(:nonexistent_skill, char)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("not found")
    end

    it "allows spending on skills with no prerequisites" do
      char = mock_character({})
      result = described_class.can_spend?(:melee_combat, char)

      expect(result[:allowed]).to be true
    end
  end

  describe ".available_for" do
    it "includes skills with met prerequisites" do
      char = mock_character(evasion: 25)
      available = described_class.available_for(char)

      expect(available).to include(:block_mastery)
    end

    it "excludes skills with unmet prerequisites" do
      char = mock_character({})
      available = described_class.available_for(char)

      expect(available).not_to include(:block_mastery)  # Needs evasion 20
      expect(available).not_to include(:critical_strikes)  # Needs melee or ranged 30
    end

    it "includes skills without prerequisites" do
      char = mock_character({})
      available = described_class.available_for(char)

      expect(available).to include(:melee_combat)
      expect(available).to include(:evasion)
    end
  end

  describe ".locked_skills_for" do
    it "returns skills with unmet prerequisites" do
      char = mock_character({})
      locked = described_class.locked_skills_for(char)

      skill_keys = locked.map { |l| l[:skill] }
      expect(skill_keys).to include(:block_mastery)
      expect(skill_keys).to include(:critical_strikes)
    end

    it "excludes skills when prerequisites are met" do
      char = mock_character(evasion: 25)
      locked = described_class.locked_skills_for(char)

      skill_keys = locked.map { |l| l[:skill] }
      expect(skill_keys).not_to include(:block_mastery)
    end

    it "excludes skills without prerequisites" do
      char = mock_character({})
      locked = described_class.locked_skills_for(char)

      skill_keys = locked.map { |l| l[:skill] }
      expect(skill_keys).not_to include(:melee_combat)
    end
  end

  describe "specific skill prerequisites" do
    let(:max_skills) do
      mock_character(
        melee_combat: 100,
        ranged_combat: 100,
        evasion: 100,
        elemental_magic: 100,
        arcane_power: 100
      )
    end

    it "critical_strikes requires melee_combat 30 or ranged_combat 30" do
      prereqs = described_class.prerequisites(:critical_strikes)
      expect(prereqs).to include({melee_combat: 30})
      expect(prereqs).to include({ranged_combat: 30})
    end

    it "block_mastery requires evasion 20" do
      prereqs = described_class.prerequisites(:block_mastery)
      expect(prereqs).to eq({evasion: 20})
    end

    it "healing_arts requires elemental_magic 30" do
      prereqs = described_class.prerequisites(:healing_arts)
      expect(prereqs).to eq({elemental_magic: 30})
    end

    it "spell_mastery requires arcane_power 20" do
      prereqs = described_class.prerequisites(:spell_mastery)
      expect(prereqs).to eq({arcane_power: 20})
    end

    it "all prerequisites can be satisfied with max skills" do
      locked = described_class.locked_skills_for(max_skills)
      expect(locked).to be_empty
    end
  end
end

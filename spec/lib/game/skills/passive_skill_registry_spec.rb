# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillRegistry do
  describe "SKILLS constant" do
    it "contains source-backed Neverlands skill definitions" do
      expect(described_class::SKILLS).to be_a(Hash)
      expect(described_class::SKILLS.keys).to include(
        :unarmed_combat,
        :sword_mastery,
        :knife_mastery,
        :fire_magic,
        :fire_magic_resistance,
        :wanderer,
        :linguistics
      )
    end

    it "does not include legacy generic skill keys" do
      expect(described_class::SKILLS.keys).not_to include(
        :melee_combat,
        :ranged_combat,
        :critical_strikes,
        :block_mastery,
        :elemental_magic,
        :arcane_power,
        :spell_mastery,
        :first_aid,
        :trading
      )
    end

    it "each skill has required source attributes" do
      described_class::SKILLS.each do |key, definition|
        expect(definition[:key]).to eq(key), "Skill #{key} has mismatched key"
        expect(definition[:source_id]).to be_an(Integer), "Skill #{key} missing source_id"
        expect(definition[:name]).to be_present, "Skill #{key} missing name"
        expect(definition[:description]).to be_present, "Skill #{key} missing description"
        expect(definition[:max_level]).to eq(100), "Skill #{key} has non-standard max_level"
        expect(definition[:category]).to be_present, "Skill #{key} missing category"
        expect(definition[:pool]).to be_in([:combat, :peace]), "Skill #{key} has invalid pool"
        expect(definition[:progression_rate]).to be_present, "Skill #{key} missing progression_rate"
        expect(definition).not_to have_key(:effect_type)
        expect(definition).not_to have_key(:effect_formula)
      end
    end

    it "has valid progression rate format" do
      described_class::SKILLS.each do |key, definition|
        parts = definition[:progression_rate].split(":")
        expect(parts.length).to eq(4), "Skill #{key} has invalid progression_rate format"
        parts.each do |part|
          expect(part.to_i).to be_between(1, 20), "Skill #{key} has unusual progression rate value"
        end
      end
    end
  end

  describe "CATEGORIES constant" do
    it "defines the captured allocation groups" do
      expect(described_class::CATEGORIES.keys).to eq(%i[combat resistance magic peace_world])
    end

    it "each category has required attributes" do
      described_class::CATEGORIES.each_value do |info|
        expect(info[:name]).to be_present
        expect(info[:pool]).to be_in([:combat, :peace])
      end
    end
  end

  describe ".find" do
    it "returns skill definition by key" do
      definition = described_class.find(:wanderer)

      expect(definition[:name]).to eq("Wanderer")
      expect(definition[:source_id]).to eq(26)
      expect(definition[:category]).to eq(:peace_world)
    end

    it "accepts string key" do
      expect(described_class.find("knife_mastery")[:source_id]).to eq(4)
    end

    it "returns nil for unknown skill" do
      expect(described_class.find(:nonexistent)).to be_nil
    end
  end

  describe ".find_by_source_id" do
    it "returns skill definition by captured Neverlands id" do
      expect(described_class.find_by_source_id(4)[:key]).to eq(:knife_mastery)
      expect(described_class.find_by_source_id(34)[:key]).to eq(:leadership)
    end

    it "returns nil for unknown source id" do
      expect(described_class.find_by_source_id(999)).to be_nil
    end
  end

  describe ".all_keys" do
    it "returns array of all skill keys" do
      keys = described_class.all_keys
      expect(keys).to be_an(Array)
      expect(keys).to include(:unarmed_combat, :fire_magic, :self_healing)
    end
  end

  describe ".all" do
    it "returns the full SKILLS hash" do
      expect(described_class.all).to eq(described_class::SKILLS)
    end
  end

  describe ".by_category" do
    it "returns skills in specified category" do
      combat_skills = described_class.by_category(:combat)

      expect(combat_skills).to be_an(Array)
      expect(combat_skills).to all(include(category: :combat))
    end

    it "returns empty array for unknown category" do
      expect(described_class.by_category(:nonexistent)).to eq([])
    end
  end

  describe ".by_pool" do
    it "returns skills using combat pool" do
      combat_pool_skills = described_class.by_pool(:combat)

      expect(combat_pool_skills).not_to be_empty
      expect(combat_pool_skills).to all(include(pool: :combat))
    end

    it "returns skills using peace pool" do
      peace_pool_skills = described_class.by_pool(:peace)

      expect(peace_pool_skills).not_to be_empty
      expect(peace_pool_skills).to all(include(pool: :peace))
    end
  end

  describe ".valid?" do
    it "returns true for existing skill" do
      expect(described_class.valid?(:wanderer)).to be true
      expect(described_class.valid?("sword_mastery")).to be true
    end

    it "returns false for nonexistent skill" do
      expect(described_class.valid?(:nonexistent)).to be false
    end
  end

  describe ".calculate_effect" do
    it "returns zero until Neverlands formulas are captured" do
      expect(described_class.calculate_effect(:wanderer, 100)).to eq(0.0)
      expect(described_class.calculate_effect(:fire_magic, 100)).to eq(0.0)
      expect(described_class.calculate_effect(:nonexistent, 50)).to eq(0.0)
    end
  end

  describe ".max_level" do
    it "returns 100 for all skills" do
      described_class.all_keys.each do |key|
        expect(described_class.max_level(key)).to eq(100)
      end
    end

    it "returns nil for unknown skill" do
      expect(described_class.max_level(:nonexistent)).to be_nil
    end
  end

  describe ".progression_rate" do
    it "returns captured Neverlands progression rates" do
      expect(described_class.progression_rate(:unarmed_combat)).to eq("10:8:6:4")
      expect(described_class.progression_rate(:sword_mastery)).to eq("8:6:4:2")
      expect(described_class.progression_rate(:self_healing)).to eq("2:2:2:2")
      expect(described_class.progression_rate(:leadership)).to eq("6:4:3:2")
    end

    it "returns no fallback rate for unknown skill" do
      expect(described_class.progression_rate(:nonexistent)).to be_nil
    end
  end

  describe ".pool_for" do
    it "returns combat pool for combat, magic, and resistance skills" do
      expect(described_class.pool_for(:unarmed_combat)).to eq(:combat)
      expect(described_class.pool_for(:fire_magic)).to eq(:combat)
      expect(described_class.pool_for(:fire_magic_resistance)).to eq(:combat)
    end

    it "returns peace pool for peace/world skills" do
      expect(described_class.pool_for(:wanderer)).to eq(:peace)
      expect(described_class.pool_for(:linguistics)).to eq(:peace)
    end
  end

  describe ".grouped_by_category" do
    it "returns skills grouped by category" do
      grouped = described_class.grouped_by_category

      expect(grouped.keys).to include(:combat, :magic, :peace_world)
      expect(grouped[:combat]).to include(:unarmed_combat, :sword_mastery)
      expect(grouped[:peace_world]).to include(:self_healing, :linguistics)
    end
  end

  describe ".prerequisites" do
    it "does not define uncaptured prerequisite rules" do
      expect(described_class.prerequisites(:sword_mastery)).to be_nil
      expect(described_class.prerequisites_met?(:sword_mastery, nil)).to eq({met: true, missing: []})
      expect(described_class.locked_skills_for(nil)).to eq([])
    end
  end

  describe "skill categories distribution" do
    it "has combat-like skills using combat pool" do
      expect(described_class.by_category(:combat)).to all(include(pool: :combat))
      expect(described_class.by_category(:magic)).to all(include(pool: :combat))
      expect(described_class.by_category(:resistance)).to all(include(pool: :combat))
    end

    it "has peace/world skills using peace pool" do
      expect(described_class.by_category(:peace_world)).to all(include(pool: :peace))
    end
  end
end

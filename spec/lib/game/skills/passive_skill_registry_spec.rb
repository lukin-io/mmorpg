# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillRegistry do
  describe "SKILLS constant" do
    it "contains skill definitions" do
      expect(described_class::SKILLS).to be_a(Hash)
      expect(described_class::SKILLS).not_to be_empty
    end

    it "each skill has required attributes" do
      described_class::SKILLS.each do |key, definition|
        expect(definition[:key]).to eq(key), "Skill #{key} has mismatched key"
        expect(definition[:name]).to be_present, "Skill #{key} missing name"
        expect(definition[:description]).to be_present, "Skill #{key} missing description"
        expect(definition[:max_level]).to eq(100), "Skill #{key} has non-standard max_level"
        expect(definition[:category]).to be_present, "Skill #{key} missing category"
        expect(definition[:pool]).to be_in([:combat, :peace]), "Skill #{key} has invalid pool"
        expect(definition[:effect_type]).to be_present, "Skill #{key} missing effect_type"
        expect(definition[:effect_formula]).to respond_to(:call), "Skill #{key} missing effect_formula"
        expect(definition[:progression_rate]).to be_present, "Skill #{key} missing progression_rate"
      end
    end

    it "has valid progression rate format" do
      described_class::SKILLS.each do |key, definition|
        rate = definition[:progression_rate]
        parts = rate.split(":")
        expect(parts.length).to eq(4), "Skill #{key} has invalid progression_rate format"
        parts.each do |part|
          expect(part.to_i).to be_between(1, 20), "Skill #{key} has unusual progression rate value"
        end
      end
    end
  end

  describe "CATEGORIES constant" do
    it "defines all expected categories" do
      expect(described_class::CATEGORIES.keys).to include(:combat, :magic, :resistance, :survival, :peace)
    end

    it "each category has required attributes" do
      described_class::CATEGORIES.each do |key, info|
        expect(info[:name]).to be_present
        expect(info[:pool]).to be_in([:combat, :peace])
      end
    end
  end

  describe ".find" do
    it "returns skill definition by key" do
      definition = described_class.find(:wanderer)
      expect(definition[:name]).to eq("Wanderer")
      expect(definition[:category]).to eq(:survival)
    end

    it "accepts string key" do
      definition = described_class.find("wanderer")
      expect(definition[:name]).to eq("Wanderer")
    end

    it "returns nil for unknown skill" do
      expect(described_class.find(:nonexistent)).to be_nil
    end
  end

  describe ".all_keys" do
    it "returns array of all skill keys" do
      keys = described_class.all_keys
      expect(keys).to be_an(Array)
      expect(keys).to include(:wanderer, :melee_combat, :herbalism)
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
      expect(combat_skills).to all(have_key(:category))
      expect(combat_skills.map { |s| s[:category] }.uniq).to eq([:combat])
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
      expect(described_class.valid?("melee_combat")).to be true
    end

    it "returns false for nonexistent skill" do
      expect(described_class.valid?(:nonexistent)).to be false
    end
  end

  describe ".calculate_effect" do
    it "calculates wanderer effect (movement cooldown reduction)" do
      expect(described_class.calculate_effect(:wanderer, 0)).to eq(0.0)
      expect(described_class.calculate_effect(:wanderer, 50)).to be_within(0.01).of(0.35)
      expect(described_class.calculate_effect(:wanderer, 100)).to be_within(0.01).of(0.70)
    end

    it "calculates melee combat effect (damage bonus)" do
      expect(described_class.calculate_effect(:melee_combat, 0)).to eq(0.0)
      expect(described_class.calculate_effect(:melee_combat, 100)).to be_within(0.01).of(0.50)
    end

    it "clamps level to valid range" do
      expect(described_class.calculate_effect(:wanderer, 150)).to eq(described_class.calculate_effect(:wanderer, 100))
      expect(described_class.calculate_effect(:wanderer, -50)).to eq(described_class.calculate_effect(:wanderer, 0))
    end

    it "returns 0 for unknown skill" do
      expect(described_class.calculate_effect(:nonexistent, 50)).to eq(0.0)
    end
  end

  describe ".max_level" do
    it "returns 100 for all skills" do
      described_class.all_keys.each do |key|
        expect(described_class.max_level(key)).to eq(100)
      end
    end

    it "returns 100 for unknown skill (default)" do
      expect(described_class.max_level(:nonexistent)).to eq(100)
    end
  end

  describe ".progression_rate" do
    it "returns skill progression rate string" do
      expect(described_class.progression_rate(:wanderer)).to eq("10:8:6:4")
      expect(described_class.progression_rate(:herbalism)).to eq("2:2:2:2")
    end

    it "returns default rate for unknown skill" do
      expect(described_class.progression_rate(:nonexistent)).to eq("8:6:4:2")
    end
  end

  describe ".pool_for" do
    it "returns combat pool for combat skills" do
      expect(described_class.pool_for(:melee_combat)).to eq(:combat)
      expect(described_class.pool_for(:elemental_magic)).to eq(:combat)
      expect(described_class.pool_for(:wanderer)).to eq(:combat)
    end

    it "returns peace pool for peace skills" do
      expect(described_class.pool_for(:herbalism)).to eq(:peace)
      expect(described_class.pool_for(:fishing)).to eq(:peace)
      expect(described_class.pool_for(:trading)).to eq(:peace)
    end
  end

  describe ".categories" do
    it "returns category definitions" do
      expect(described_class.categories).to eq(described_class::CATEGORIES)
    end
  end

  describe ".grouped_by_category" do
    it "returns skills grouped by category" do
      grouped = described_class.grouped_by_category
      expect(grouped).to be_a(Hash)
      expect(grouped.keys).to include(:combat, :magic, :peace)
      expect(grouped[:combat]).to include(:melee_combat, :ranged_combat)
      expect(grouped[:peace]).to include(:herbalism, :fishing)
    end
  end

  describe "skill categories distribution" do
    it "has combat skills using combat pool" do
      combat_skills = described_class.by_category(:combat)
      expect(combat_skills).to all(include(pool: :combat))
    end

    it "has magic skills using combat pool" do
      magic_skills = described_class.by_category(:magic)
      expect(magic_skills).to all(include(pool: :combat))
    end

    it "has resistance skills using combat pool" do
      resistance_skills = described_class.by_category(:resistance)
      expect(resistance_skills).to all(include(pool: :combat))
    end

    it "has survival skills using combat pool" do
      survival_skills = described_class.by_category(:survival)
      expect(survival_skills).to all(include(pool: :combat))
    end

    it "has peace skills using peace pool" do
      peace_skills = described_class.by_category(:peace)
      expect(peace_skills).to all(include(pool: :peace))
    end
  end
end

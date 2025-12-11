# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillRegistry do
  describe ".find" do
    it "returns skill definition for valid key" do
      definition = described_class.find(:wanderer)

      expect(definition).to be_present
      expect(definition[:key]).to eq(:wanderer)
      expect(definition[:name]).to eq("Wanderer")
      expect(definition[:max_level]).to eq(100)
      expect(definition[:category]).to eq(:movement)
    end

    it "returns nil for invalid key" do
      expect(described_class.find(:nonexistent)).to be_nil
    end

    it "accepts string keys" do
      expect(described_class.find("wanderer")).to be_present
    end
  end

  describe ".all_keys" do
    it "returns array of skill keys" do
      keys = described_class.all_keys

      expect(keys).to be_an(Array)
      expect(keys).to include(:wanderer)
    end
  end

  describe ".valid?" do
    it "returns true for valid skill" do
      expect(described_class.valid?(:wanderer)).to be true
    end

    it "returns false for invalid skill" do
      expect(described_class.valid?(:nonexistent)).to be false
    end
  end

  describe ".calculate_effect" do
    context "for wanderer skill" do
      it "returns 0 at level 0" do
        effect = described_class.calculate_effect(:wanderer, 0)

        expect(effect).to eq(0.0)
      end

      it "returns 0.35 at level 50" do
        effect = described_class.calculate_effect(:wanderer, 50)

        expect(effect).to eq(0.35)
      end

      it "returns 0.70 at level 100" do
        effect = described_class.calculate_effect(:wanderer, 100)

        expect(effect).to eq(0.70)
      end

      it "clamps level to max" do
        effect_at_100 = described_class.calculate_effect(:wanderer, 100)
        effect_at_150 = described_class.calculate_effect(:wanderer, 150)

        expect(effect_at_150).to eq(effect_at_100)
      end

      it "returns 0 for negative levels" do
        effect = described_class.calculate_effect(:wanderer, -10)

        expect(effect).to eq(0.0)
      end
    end

    it "returns 0 for unknown skill" do
      expect(described_class.calculate_effect(:nonexistent, 50)).to eq(0.0)
    end
  end

  describe ".max_level" do
    it "returns max level for known skill" do
      expect(described_class.max_level(:wanderer)).to eq(100)
    end

    it "returns default 100 for unknown skill" do
      expect(described_class.max_level(:nonexistent)).to eq(100)
    end
  end

  describe ".by_category" do
    it "returns skills in specified category" do
      movement_skills = described_class.by_category(:movement)

      expect(movement_skills).to be_an(Array)
      expect(movement_skills.map { |s| s[:key] }).to include(:wanderer)
    end

    it "returns empty array for unknown category" do
      expect(described_class.by_category(:unknown)).to eq([])
    end
  end
end

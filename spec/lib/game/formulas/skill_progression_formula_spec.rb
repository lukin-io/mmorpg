# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::SkillProgressionFormula do
  subject(:formula) { described_class.new }

  describe "#points_per_spend" do
    context "with string rate format" do
      let(:fast_rate) { "10:8:6:4" }
      let(:slow_rate) { "2:2:2:2" }

      it "returns first tier rate for levels 0-24" do
        (0..24).each do |level|
          expect(formula.points_per_spend(current_level: level, progression_rate: fast_rate)).to eq(10),
            "Expected 10 points at level #{level}, got #{formula.points_per_spend(current_level: level, progression_rate: fast_rate)}"
        end
      end

      it "returns second tier rate for levels 25-49" do
        (25..49).each do |level|
          expect(formula.points_per_spend(current_level: level, progression_rate: fast_rate)).to eq(8),
            "Expected 8 points at level #{level}"
        end
      end

      it "returns third tier rate for levels 50-74" do
        (50..74).each do |level|
          expect(formula.points_per_spend(current_level: level, progression_rate: fast_rate)).to eq(6),
            "Expected 6 points at level #{level}"
        end
      end

      it "returns fourth tier rate for levels 75-96" do
        (75..96).each do |level|
          expect(formula.points_per_spend(current_level: level, progression_rate: fast_rate)).to eq(4),
            "Expected 4 points at level #{level}"
        end
      end

      it "caps points to not exceed max level" do
        # At level 97, adding 4 would give 101, so it's capped to 3
        expect(formula.points_per_spend(current_level: 97, progression_rate: fast_rate)).to eq(3)
        # At level 98, adding 4 would give 102, so it's capped to 2
        expect(formula.points_per_spend(current_level: 98, progression_rate: fast_rate)).to eq(2)
        # At level 99, adding 4 would give 103, so it's capped to 1
        expect(formula.points_per_spend(current_level: 99, progression_rate: fast_rate)).to eq(1)
      end

      it "returns slow rate for peace skills" do
        expect(formula.points_per_spend(current_level: 50, progression_rate: slow_rate)).to eq(2)
      end
    end

    context "with symbol rate format" do
      it "looks up predefined rates" do
        expect(formula.points_per_spend(current_level: 0, progression_rate: :fast)).to eq(10)
        expect(formula.points_per_spend(current_level: 0, progression_rate: :medium)).to eq(8)
        expect(formula.points_per_spend(current_level: 0, progression_rate: :slow)).to eq(4)
        expect(formula.points_per_spend(current_level: 0, progression_rate: :very_slow)).to eq(2)
      end
    end

    context "with array rate format" do
      it "accepts array of integers" do
        expect(formula.points_per_spend(current_level: 0, progression_rate: [5, 4, 3, 2])).to eq(5)
        expect(formula.points_per_spend(current_level: 50, progression_rate: [5, 4, 3, 2])).to eq(3)
      end
    end

    context "near max level" do
      it "does not exceed max level" do
        expect(formula.points_per_spend(current_level: 97, progression_rate: "10:8:6:4")).to eq(3)
        expect(formula.points_per_spend(current_level: 99, progression_rate: "10:8:6:4")).to eq(1)
      end

      it "returns 0 at max level" do
        expect(formula.points_per_spend(current_level: 100, progression_rate: "10:8:6:4")).to eq(0)
      end
    end
  end

  describe "#apply_spend" do
    let(:fast_rate) { "10:8:6:4" }

    it "adds points based on tier" do
      expect(formula.apply_spend(current_level: 0, progression_rate: fast_rate)).to eq(10)
      expect(formula.apply_spend(current_level: 10, progression_rate: fast_rate)).to eq(20)
      expect(formula.apply_spend(current_level: 20, progression_rate: fast_rate)).to eq(30)
      expect(formula.apply_spend(current_level: 30, progression_rate: fast_rate)).to eq(38)
      expect(formula.apply_spend(current_level: 50, progression_rate: fast_rate)).to eq(56)
    end

    it "caps at max level" do
      expect(formula.apply_spend(current_level: 97, progression_rate: fast_rate)).to eq(100)
      expect(formula.apply_spend(current_level: 100, progression_rate: fast_rate)).to eq(100)
    end
  end

  describe "#spends_to_reach" do
    let(:fast_rate) { "10:8:6:4" }

    it "calculates spends needed for a skill from 0 to 100" do
      # For "10:8:6:4" skill, ~16 spends are needed to reach 100
      spends = formula.spends_to_reach(from_level: 0, to_level: 100, progression_rate: fast_rate)
      expect(spends).to be_between(15, 17)
    end

    it "returns 0 if already at target" do
      expect(formula.spends_to_reach(from_level: 50, to_level: 50, progression_rate: fast_rate)).to eq(0)
      expect(formula.spends_to_reach(from_level: 100, to_level: 50, progression_rate: fast_rate)).to eq(0)
    end

    it "calculates partial spends" do
      expect(formula.spends_to_reach(from_level: 0, to_level: 10, progression_rate: fast_rate)).to eq(1)
      expect(formula.spends_to_reach(from_level: 0, to_level: 25, progression_rate: fast_rate)).to eq(3)
    end
  end

  describe "#remove_spend" do
    let(:fast_rate) { "10:8:6:4" }

    it "removes points based on tier" do
      expect(formula.remove_spend(current_level: 10, base_level: 0, progression_rate: fast_rate)).to eq(0)
      expect(formula.remove_spend(current_level: 20, base_level: 0, progression_rate: fast_rate)).to eq(10)
      expect(formula.remove_spend(current_level: 38, base_level: 0, progression_rate: fast_rate)).to eq(30)
    end

    it "does not go below base level" do
      expect(formula.remove_spend(current_level: 10, base_level: 10, progression_rate: fast_rate)).to eq(10)
      expect(formula.remove_spend(current_level: 20, base_level: 15, progression_rate: fast_rate)).to eq(15)
    end

    it "handles tier boundaries correctly" do
      # At level 30 (tier 1), removing should use tier 0 rate (10) to get back to 20
      # This tests the boundary handling
      result = formula.remove_spend(current_level: 30, base_level: 0, progression_rate: fast_rate)
      expect(result).to eq(20)
    end
  end

  describe "#progression_preview" do
    it "returns tier breakdown" do
      preview = formula.progression_preview(progression_rate: "10:8:6:4")
      expect(preview).to eq({
        "0-24" => 10,
        "25-49" => 8,
        "50-74" => 6,
        "75-99" => 4
      })
    end
  end

  describe "edge cases" do
    it "handles nil rate gracefully" do
      expect(formula.points_per_spend(current_level: 0, progression_rate: nil)).to eq(8)
    end

    it "handles empty string rate" do
      expect(formula.points_per_spend(current_level: 0, progression_rate: "")).to be_an(Integer)
    end

    it "handles unknown symbol rate" do
      expect(formula.points_per_spend(current_level: 0, progression_rate: :unknown)).to eq(8)
    end

    it "handles negative level" do
      expect(formula.points_per_spend(current_level: -5, progression_rate: "10:8:6:4")).to eq(10)
    end
  end

  describe "deterministic behavior" do
    it "always returns the same result for the same inputs" do
      100.times do
        expect(formula.points_per_spend(current_level: 42, progression_rate: "10:8:6:4")).to eq(8)
      end
    end
  end

  describe "tiered progression simulation" do
    # Simulates the exact progression table for tiered skills
    it "matches expected progression for skill with rate 10:8:6:4" do
      rate = "10:8:6:4"
      level = 0
      spends = 0

      # Expected progression with tiered rates:
      # Click 1: 0 → 10, Click 2: 10 → 20, Click 3: 20 → 30
      # Click 4: 30 → 38, Click 5: 38 → 46, Click 6: 46 → 54
      # etc.

      expected_levels = [10, 20, 30, 38, 46, 54, 60, 66, 72, 78, 82, 86, 90, 94, 98, 100]

      while level < 100
        level = formula.apply_spend(current_level: level, progression_rate: rate)
        spends += 1
        expect(level).to eq(expected_levels[spends - 1]),
          "After spend #{spends}, expected level #{expected_levels[spends - 1]}, got #{level}"
        break if spends >= expected_levels.length
      end
    end
  end
end

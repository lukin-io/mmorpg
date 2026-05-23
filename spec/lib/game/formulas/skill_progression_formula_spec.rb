# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::SkillProgressionFormula do
  subject(:formula) { described_class.new }

  describe "#points_per_spend" do
    let(:captured_rate) { "10:8:6:4" }

    it "returns first tier rate for levels 0-24" do
      (0..24).each do |level|
        expect(formula.points_per_spend(current_level: level, progression_rate: captured_rate)).to eq(10)
      end
    end

    it "returns second tier rate for levels 25-49" do
      (25..49).each do |level|
        expect(formula.points_per_spend(current_level: level, progression_rate: captured_rate)).to eq(8)
      end
    end

    it "returns third tier rate for levels 50-74" do
      (50..74).each do |level|
        expect(formula.points_per_spend(current_level: level, progression_rate: captured_rate)).to eq(6)
      end
    end

    it "returns fourth tier rate for levels 75-96" do
      (75..96).each do |level|
        expect(formula.points_per_spend(current_level: level, progression_rate: captured_rate)).to eq(4)
      end
    end

    it "caps points to not exceed max level" do
      expect(formula.points_per_spend(current_level: 97, progression_rate: captured_rate)).to eq(3)
      expect(formula.points_per_spend(current_level: 98, progression_rate: captured_rate)).to eq(2)
      expect(formula.points_per_spend(current_level: 99, progression_rate: captured_rate)).to eq(1)
      expect(formula.points_per_spend(current_level: 100, progression_rate: captured_rate)).to eq(0)
    end

    it "rejects uncaptured or malformed rates instead of inventing defaults" do
      expect {
        formula.points_per_spend(current_level: 0, progression_rate: :fast)
      }.to raise_error(ArgumentError)

      expect {
        formula.points_per_spend(current_level: 0, progression_rate: nil)
      }.to raise_error(ArgumentError)

      expect {
        formula.points_per_spend(current_level: 0, progression_rate: "")
      }.to raise_error(ArgumentError)
    end
  end

  describe "#apply_spend" do
    let(:captured_rate) { "10:8:6:4" }

    it "adds points based on captured tiers" do
      expect(formula.apply_spend(current_level: 0, progression_rate: captured_rate)).to eq(10)
      expect(formula.apply_spend(current_level: 10, progression_rate: captured_rate)).to eq(20)
      expect(formula.apply_spend(current_level: 20, progression_rate: captured_rate)).to eq(30)
      expect(formula.apply_spend(current_level: 30, progression_rate: captured_rate)).to eq(38)
      expect(formula.apply_spend(current_level: 50, progression_rate: captured_rate)).to eq(56)
    end

    it "caps at max level" do
      expect(formula.apply_spend(current_level: 97, progression_rate: captured_rate)).to eq(100)
      expect(formula.apply_spend(current_level: 100, progression_rate: captured_rate)).to eq(100)
    end
  end

  describe "#remove_spend" do
    let(:captured_rate) { "10:8:6:4" }

    it "removes points based on captured tiers" do
      expect(formula.remove_spend(current_level: 10, base_level: 0, progression_rate: captured_rate)).to eq(0)
      expect(formula.remove_spend(current_level: 20, base_level: 0, progression_rate: captured_rate)).to eq(10)
      expect(formula.remove_spend(current_level: 38, base_level: 0, progression_rate: captured_rate)).to eq(30)
    end

    it "does not go below base level" do
      expect(formula.remove_spend(current_level: 10, base_level: 10, progression_rate: captured_rate)).to eq(10)
      expect(formula.remove_spend(current_level: 20, base_level: 15, progression_rate: captured_rate)).to eq(15)
    end

    it "handles tier boundaries correctly" do
      expect(formula.remove_spend(current_level: 30, base_level: 0, progression_rate: captured_rate)).to eq(20)
    end
  end
end

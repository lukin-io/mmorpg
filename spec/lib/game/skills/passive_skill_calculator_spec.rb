# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillCalculator do
  let(:character) { create(:character, passive_skills: passive_skills) }
  let(:passive_skills) { {} }
  let(:calculator) { described_class.new(character) }

  describe "#skill_level" do
    context "when skill is not set" do
      it "returns 0" do
        expect(calculator.skill_level(:wanderer)).to eq(0)
      end
    end

    context "when skill is set" do
      let(:passive_skills) { {"wanderer" => 50} }

      it "returns the skill level" do
        expect(calculator.skill_level(:wanderer)).to eq(50)
      end

      it "accepts symbol keys" do
        expect(calculator.skill_level(:wanderer)).to eq(50)
      end

      it "accepts string keys" do
        expect(calculator.skill_level("wanderer")).to eq(50)
      end
    end
  end

  describe "#movement_cooldown_modifier" do
    context "with wanderer at 0" do
      let(:passive_skills) { {"wanderer" => 0} }

      it "returns 0 reduction" do
        expect(calculator.movement_cooldown_modifier).to eq(0.0)
      end
    end

    context "with wanderer at 50" do
      let(:passive_skills) { {"wanderer" => 50} }

      it "returns 35% reduction" do
        expect(calculator.movement_cooldown_modifier).to eq(0.35)
      end
    end

    context "with wanderer at 100" do
      let(:passive_skills) { {"wanderer" => 100} }

      it "returns 70% reduction" do
        expect(calculator.movement_cooldown_modifier).to eq(0.70)
      end
    end
  end

  describe "#apply_movement_cooldown" do
    context "with wanderer at 0" do
      let(:passive_skills) { {"wanderer" => 0} }

      it "returns base cooldown of 10 seconds" do
        expect(calculator.apply_movement_cooldown).to eq(10.0)
      end

      it "accepts custom base cooldown" do
        expect(calculator.apply_movement_cooldown(20)).to eq(20.0)
      end
    end

    context "with wanderer at 50" do
      let(:passive_skills) { {"wanderer" => 50} }

      it "returns 6.5 seconds (35% reduction)" do
        expect(calculator.apply_movement_cooldown).to eq(6.5)
      end
    end

    context "with wanderer at 100" do
      let(:passive_skills) { {"wanderer" => 100} }

      it "returns 3.0 seconds (70% reduction)" do
        expect(calculator.apply_movement_cooldown).to eq(3.0)
      end
    end

    context "with no wanderer skill" do
      let(:passive_skills) { {} }

      it "returns base cooldown" do
        expect(calculator.apply_movement_cooldown).to eq(10.0)
      end
    end
  end

  describe "#all_modifiers" do
    let(:passive_skills) { {"wanderer" => 50} }

    it "returns hash with all modifier values" do
      modifiers = calculator.all_modifiers

      expect(modifiers).to be_a(Hash)
      expect(modifiers[:movement_cooldown_reduction]).to eq(0.35)
    end
  end

  describe "#skill_summary" do
    let(:passive_skills) { {"wanderer" => 25} }

    it "returns array of skill summaries" do
      summary = calculator.skill_summary

      expect(summary).to be_an(Array)

      wanderer = summary.find { |s| s[:key] == :wanderer }
      expect(wanderer).to be_present
      expect(wanderer[:name]).to eq("Wanderer")
      expect(wanderer[:level]).to eq(25)
      expect(wanderer[:max_level]).to eq(100)
      expect(wanderer[:effect_value]).to eq(0.175)
      expect(wanderer[:effect_type]).to eq(:movement_cooldown_reduction)
    end
  end

  describe "with nil character" do
    let(:calculator) { described_class.new(nil) }

    it "handles nil gracefully" do
      expect(calculator.skill_level(:wanderer)).to eq(0)
      expect(calculator.apply_movement_cooldown).to eq(10.0)
    end
  end
end

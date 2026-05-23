# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PassiveSkillCalculator do
  let(:character) { create(:character, passive_skills:) }
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

      it "accepts string keys" do
        expect(calculator.skill_level("wanderer")).to eq(50)
      end
    end
  end

  describe "#skill_summary" do
    let(:passive_skills) { {"wanderer" => 25} }

    it "returns captured skill metadata without invented effect data" do
      summary = calculator.skill_summary
      wanderer = summary.find { |skill| skill[:key] == :wanderer }

      expect(wanderer).to include(
        source_id: 26,
        name: "Странник",
        level: 25,
        max_level: 100,
        progression_rate: "2:2:2:2",
        pool: :peace,
        category: :peace_world
      )
      expect(wanderer).not_to have_key(:effect_value)
      expect(wanderer).not_to have_key(:effect_type)
    end
  end

  describe "with nil character" do
    let(:calculator) { described_class.new(nil) }

    it "handles nil gracefully" do
      expect(calculator.skill_level(:wanderer)).to eq(0)
    end
  end
end

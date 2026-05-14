# frozen_string_literal: true

require "rails_helper"

RSpec.describe Players::Progression::LevelUpService do
  let(:user) { create(:user) }
  let(:character) do
    create(:character,
      user: user,
      level: 1,
      experience: 0,
      stat_points_available: 0,
      skill_points_available: 0,
      combat_skill_points: 0,
      peace_skill_points: 0,
      perk_points_available: 0)
  end

  describe "#apply_experience!" do
    context "when experience is not enough to level up" do
      it "adds experience without leveling" do
        service = described_class.new(character: character)
        result = service.apply_experience!(99)

        expect(result.character.experience).to eq(99)
        expect(result.character.level).to eq(1)
        expect(result.levels_gained).to eq(0)
      end
    end

    context "when experience triggers one level up" do
      it "increases level and grants stat points" do
        # Level 2 requires 100 total XP.
        service = described_class.new(character: character)
        result = service.apply_experience!(100)

        expect(result.character.level).to eq(2)
        expect(result.levels_gained).to eq(1)
        expect(result.stat_points_gained).to eq(5)
        expect(result.character.stat_points_available).to eq(5)
      end

      it "grants combat skill points" do
        service = described_class.new(character: character)
        result = service.apply_experience!(100)

        expect(result.combat_skill_points_gained).to eq(1)
        expect(result.character.combat_skill_points).to eq(1)
      end

      it "does not grant peace skill points before level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(100)

        expect(result.peace_skill_points_gained).to eq(0)
        expect(result.character.peace_skill_points).to eq(0)
      end

      it "does not grant perk points before level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(100)

        expect(result.perk_points_gained).to eq(0)
        expect(result.character.perk_points_available).to eq(0)
      end
    end

    context "when leveling to level 5" do
      let(:character) do
        create(:character,
          user: user,
          level: 4,
          experience: 900,  # Level 5 requires 1600
          stat_points_available: 0,
          combat_skill_points: 0,
          peace_skill_points: 0,
          perk_points_available: 0)
      end

      it "grants peace skill points at level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(700)  # Total 1600 XP

        expect(result.character.level).to eq(5)
        expect(result.peace_skill_points_gained).to eq(1)
        expect(result.character.peace_skill_points).to eq(1)
      end

      it "grants a perk point at level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(700)

        expect(result.perk_points_gained).to eq(1)
        expect(result.character.perk_points_available).to eq(1)
      end
    end

    context "when leveling multiple levels" do
      it "grants cumulative rewards" do
        # Level up from 1 to 5 requires total of 1600 XP
        # Level 2: 100, Level 3: 400, Level 4: 900, Level 5: 1600
        service = described_class.new(character: character)
        result = service.apply_experience!(1600)

        expect(result.character.level).to eq(5)
        expect(result.levels_gained).to eq(4)
        expect(result.stat_points_gained).to eq(20)  # 4 levels * 5 points
        expect(result.combat_skill_points_gained).to eq(4)  # 4 levels * 1 point
        expect(result.peace_skill_points_gained).to eq(1)  # Only level 5 grants peace points
        expect(result.perk_points_gained).to eq(1)  # Only level 5 grants perk point
      end
    end

    context "when leveling to level 10" do
      let(:character) do
        create(:character,
          user: user,
          level: 9,
          experience: 6400,  # Level 10 requires 8100
          stat_points_available: 0,
          combat_skill_points: 0,
          peace_skill_points: 0,
          perk_points_available: 0)
      end

      it "grants perk point at level 10" do
        service = described_class.new(character: character)
        result = service.apply_experience!(1700)

        expect(result.character.level).to eq(10)
        expect(result.perk_points_gained).to eq(1)
        expect(result.character.perk_points_available).to eq(1)
      end
    end
  end

  describe "#force_level_up!" do
    it "grants one level worth of rewards" do
      service = described_class.new(character: character)
      result = service.force_level_up!

      expect(result.character.level).to eq(2)
      expect(result.levels_gained).to eq(1)
      expect(result.stat_points_gained).to eq(5)
    end

    it "grants multiple levels worth of rewards" do
      service = described_class.new(character: character)
      result = service.force_level_up!(levels: 5)

      expect(result.character.level).to eq(6)
      expect(result.levels_gained).to eq(5)
      expect(result.stat_points_gained).to eq(25)
      expect(result.perk_points_gained).to eq(1)  # Level 5 grants perk point
    end
  end

  describe "XP formula" do
    it "calculates correct XP for each level" do
      # Formula: (level - 1)^2 * 100, with level 2 at 100 total XP.
      expect(Character.xp_required_for_level(1)).to eq(0)
      expect(Character.xp_required_for_level(2)).to eq(100)
      expect(Character.xp_required_for_level(5)).to eq(1600)
      expect(Character.xp_required_for_level(10)).to eq(8100)
    end
  end
end

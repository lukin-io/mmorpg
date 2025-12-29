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
        result = service.apply_experience!(100)

        expect(result.character.experience).to eq(100)
        expect(result.character.level).to eq(1)
        expect(result.levels_gained).to eq(0)
      end
    end

    context "when experience triggers one level up" do
      it "increases level and grants stat points" do
        # Level 2 requires 400 XP (2^2 * 100)
        service = described_class.new(character: character)
        result = service.apply_experience!(500)

        expect(result.character.level).to eq(2)
        expect(result.levels_gained).to eq(1)
        expect(result.stat_points_gained).to eq(5)
        expect(result.character.stat_points_available).to eq(5)
      end

      it "grants combat skill points" do
        service = described_class.new(character: character)
        result = service.apply_experience!(500)

        expect(result.combat_skill_points_gained).to eq(1)
        expect(result.character.combat_skill_points).to eq(1)
      end

      it "does not grant peace skill points before level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(500)

        expect(result.peace_skill_points_gained).to eq(0)
        expect(result.character.peace_skill_points).to eq(0)
      end

      it "does not grant perk points before level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(500)

        expect(result.perk_points_gained).to eq(0)
        expect(result.character.perk_points_available).to eq(0)
      end
    end

    context "when leveling to level 5" do
      let(:character) do
        create(:character,
          user: user,
          level: 4,
          experience: 1600,  # Level 5 requires 2500
          stat_points_available: 0,
          combat_skill_points: 0,
          peace_skill_points: 0,
          perk_points_available: 0)
      end

      it "grants peace skill points at level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(1000)  # Total 2600 XP

        expect(result.character.level).to eq(5)
        expect(result.peace_skill_points_gained).to eq(1)
        expect(result.character.peace_skill_points).to eq(1)
      end

      it "grants a perk point at level 5" do
        service = described_class.new(character: character)
        result = service.apply_experience!(1000)

        expect(result.perk_points_gained).to eq(1)
        expect(result.character.perk_points_available).to eq(1)
      end
    end

    context "when leveling multiple levels" do
      it "grants cumulative rewards" do
        # Level up from 1 to 5 requires total of 2500 XP
        # Level 2: 400, Level 3: 900, Level 4: 1600, Level 5: 2500
        service = described_class.new(character: character)
        result = service.apply_experience!(3000)

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
          experience: 8100,  # Level 10 requires 10000
          stat_points_available: 0,
          combat_skill_points: 0,
          peace_skill_points: 0,
          perk_points_available: 0)
      end

      it "grants perk point at level 10" do
        service = described_class.new(character: character)
        result = service.apply_experience!(2000)

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
      # Formula: level^2 * 100
      expect(1**2 * 100).to eq(100)   # Can't be level 0, so this is level 1
      expect(2**2 * 100).to eq(400)   # Level 2
      expect(5**2 * 100).to eq(2500)  # Level 5
      expect(10**2 * 100).to eq(10000)  # Level 10
    end
  end
end

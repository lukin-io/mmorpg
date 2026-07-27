# frozen_string_literal: true

require "rails_helper"

RSpec.describe Players::Progression::LevelUpService do
  let(:character) { create(:character, :neverlands_starter) }

  describe "#apply_experience!" do
    it "adds experience below the first level threshold" do
      result = described_class.new(character:).apply_experience!(99)

      expect(result.character).to have_attributes(level: 0, experience: 99)
      expect(result.levels_gained).to eq(0)
    end

    it "applies the complete level-one grant without refilling vitals" do
      character.update!(current_hp: 2, current_mp: 3)

      result = described_class.new(character:).apply_experience!(100)

      expect(result.character).to have_attributes(
        level: 1,
        stat_points_available: 18,
        combat_skill_points: 14,
        peace_skill_points: 5,
        perk_points: 2,
        current_hp: 2,
        current_mp: 3
      )
      expect(result).to have_attributes(
        levels_gained: 1,
        stat_points_gained: 3,
        combat_skill_points_gained: 4,
        peace_skill_points_gained: 3,
        perk_points_gained: 1,
        nv_gained: 50
      )
      expect(character.user.currency_wallet.reload.nv_balance).to eq(50)
      expect(character.user.currency_wallet.currency_transactions.last.reason).to eq("progression.level_up")
    end

    it "applies every crossed catalog row exactly once" do
      result = described_class.new(character:).apply_experience!(1000)

      expect(result.character.level).to eq(4)
      expect(result).to have_attributes(
        levels_gained: 4,
        stat_points_gained: 14,
        combat_skill_points_gained: 18,
        peace_skill_points_gained: 16,
        perk_points_gained: 2,
        nv_gained: 500
      )
    end

    it "stops at the highest complete source row instead of extrapolating" do
      character.update!(level: 27, experience: 15_000_000_000)

      result = described_class.new(character:).apply_experience!(1)

      expect(result.character.level).to eq(27)
      expect(result.levels_gained).to eq(0)
    end

    it "accepts zero as a no-op boundary" do
      result = described_class.new(character:).apply_experience!(0)

      expect(result).to have_attributes(levels_gained: 0, nv_gained: 0)
    end

    it "rejects negative and null experience" do
      service = described_class.new(character:)

      expect { service.apply_experience!(-1) }
        .to raise_error(described_class::ProgressionError, /non-negative/)
      expect { service.apply_experience!(nil) }
        .to raise_error(described_class::ProgressionError, /non-negative/)
    end
  end

  describe "catalog thresholds" do
    it "uses the source-backed cumulative experience table" do
      expect(Character.xp_required_for_level(0)).to eq(0)
      expect(Character.xp_required_for_level(1)).to eq(100)
      expect(Character.xp_required_for_level(5)).to eq(1700)
      expect(Character.xp_required_for_level(10)).to eq(20_000)
      expect(Character.xp_required_for_level(28)).to be_nil
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Players::Progression::LevelUpService do
  let(:character) { create(:character, :neverlands_starter) }

  describe "#apply_experience!" do
    it "adds experience below the first level threshold" do
      result = described_class.new(character:).apply_experience!(159)

      expect(result.character).to have_attributes(level: 0, experience: 159)
      expect(result.levels_gained).to eq(0)
    end

    it "applies the complete level-one grant without refilling vitals" do
      character.update!(current_hp: 2, current_mp: 3)

      result = described_class.new(character:).apply_experience!(160)

      expect(result.character).to have_attributes(
        level: 1,
        stat_points_available: 28,
        combat_skill_points: 18,
        peace_skill_points: 6,
        perk_points: 1,
        current_hp: 2,
        current_mp: 3
      )
      expect(result).to have_attributes(
        levels_gained: 1,
        stat_points_gained: 8,
        combat_skill_points_gained: 6,
        peace_skill_points_gained: 3,
        perk_points_gained: 0,
        nv_gained: 47
      )
      expect(character.user.currency_wallet.reload.nv_balance).to eq(47)
      expect(character.user.currency_wallet.currency_transactions.last.reason).to eq("progression.level_up")
    end

    it "applies every crossed catalog row exactly once" do
      result = described_class.new(character:).apply_experience!(3500)

      expect(result.character.level).to eq(4)
      expect(result).to have_attributes(
        levels_gained: 4,
        stat_points_gained: 34,
        combat_skill_points_gained: 28,
        peace_skill_points_gained: 13,
        perk_points_gained: 1,
        nv_gained: 244
      )
    end

    it "stops at the highest authored row instead of extrapolating" do
      character.update!(level: 50, experience: 15_000_000_000)

      result = described_class.new(character:).apply_experience!(1)

      expect(result.character.level).to eq(50)
      expect(result.levels_gained).to eq(0)
    end

    it "accepts zero as a no-op boundary" do
      result = described_class.new(character:).apply_experience!(0)

      expect(result).to have_attributes(levels_gained: 0, nv_gained: 0)
    end

    it "rejects negative and null experience" do
      service = described_class.new(character:)

      expect { service.apply_experience!(-1) }
        .to raise_error(described_class::ProgressionError, I18n.t("errors.experience_non_negative"))
      expect { service.apply_experience!(nil) }
        .to raise_error(described_class::ProgressionError, I18n.t("errors.experience_non_negative"))
    end
  end

  describe "catalog thresholds" do
    it "uses the Ashen Curves cumulative table through level 50" do
      expect(Character.xp_required_for_level(0)).to eq(0)
      expect(Character.xp_required_for_level(1)).to eq(160)
      expect(Character.xp_required_for_level(10)).to eq(55_000)
      expect(Character.xp_required_for_level(50)).to eq(18_530_000)
      expect(Character.xp_required_for_level(51)).to be_nil
    end
  end
end

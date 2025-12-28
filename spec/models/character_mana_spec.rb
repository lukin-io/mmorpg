# frozen_string_literal: true

require "rails_helper"

RSpec.describe Character, "mana system" do
  let(:user) { create(:user) }
  let(:character) do
    create(:character,
      user: user,
      max_mp: 100,
      current_mp: 100,
      passive_skills: {})
  end

  describe "#effective_max_mp" do
    context "without arcane_power skill" do
      it "returns base max_mp" do
        expect(character.effective_max_mp).to eq(100)
      end
    end

    context "with arcane_power skill" do
      before do
        character.update!(passive_skills: {"arcane_power" => 50})
      end

      it "increases max_mp by skill bonus" do
        # At level 50: 50/100 * 0.30 = 15% bonus
        # 100 * 1.15 = 115
        expect(character.effective_max_mp).to eq(115)
      end
    end

    context "with max arcane_power skill" do
      before do
        character.update!(passive_skills: {"arcane_power" => 100})
      end

      it "increases max_mp by 30%" do
        # At level 100: 100/100 * 0.30 = 30% bonus
        # 100 * 1.30 = 130
        expect(character.effective_max_mp).to eq(130)
      end
    end
  end

  describe "#reduced_mana_cost" do
    context "without spell_mastery skill" do
      it "returns original cost" do
        expect(character.reduced_mana_cost(20)).to eq(20)
      end
    end

    context "with spell_mastery skill" do
      before do
        character.update!(passive_skills: {"spell_mastery" => 50})
      end

      it "reduces mana cost" do
        # At level 50: 50/100 * 0.25 = 12.5% reduction
        # 20 * (1 - 0.125) = 17.5 -> 18
        expect(character.reduced_mana_cost(20)).to eq(18)
      end
    end

    context "with max spell_mastery skill" do
      before do
        character.update!(passive_skills: {"spell_mastery" => 100})
      end

      it "reduces mana cost by 25%" do
        # At level 100: 100/100 * 0.25 = 25% reduction
        # 20 * (1 - 0.25) = 15
        expect(character.reduced_mana_cost(20)).to eq(15)
      end
    end

    it "enforces minimum 1 mana cost" do
      character.update!(passive_skills: {"spell_mastery" => 100})
      expect(character.reduced_mana_cost(1)).to be >= 1
    end
  end

  describe "#has_mana?" do
    it "returns true when has enough mana" do
      character.update!(current_mp: 50)
      expect(character.has_mana?(30)).to be true
    end

    it "returns false when not enough mana" do
      character.update!(current_mp: 10)
      expect(character.has_mana?(30)).to be false
    end

    it "considers spell_mastery reduction" do
      character.update!(
        current_mp: 15,
        passive_skills: {"spell_mastery" => 100}  # 25% reduction
      )
      # 20 mana cost reduced to 15 -> should have enough
      expect(character.has_mana?(20)).to be true
    end
  end

  describe "#spend_mana!" do
    it "reduces current_mp by reduced cost" do
      character.update!(
        current_mp: 100,
        passive_skills: {"spell_mastery" => 100}  # 25% reduction
      )

      actual_spent = character.spend_mana!(20)

      expect(actual_spent).to eq(15)  # 20 * 0.75 = 15
      expect(character.current_mp).to eq(85)
    end

    it "does not go below 0" do
      character.update!(current_mp: 5)

      character.spend_mana!(20)

      expect(character.current_mp).to eq(0)
    end

    it "returns actual mana spent" do
      actual = character.spend_mana!(30)
      expect(actual).to eq(30)
    end
  end

  describe "#regenerate_mana!" do
    before do
      character.update!(current_mp: 50, max_mp: 100)
    end

    it "regenerates 5% of effective_max_mp per tick" do
      regenerated = character.regenerate_mana!

      # 100 * 0.05 = 5
      expect(regenerated).to eq(5)
      expect(character.current_mp).to eq(55)
    end

    it "regenerates multiple ticks" do
      regenerated = character.regenerate_mana!(3)

      # 5 * 3 = 15
      expect(regenerated).to eq(15)
      expect(character.current_mp).to eq(65)
    end

    it "does not exceed effective_max_mp" do
      character.update!(current_mp: 98)

      character.regenerate_mana!(2)

      expect(character.current_mp).to eq(100)
    end

    it "considers arcane_power for max_mp cap" do
      character.update!(
        current_mp: 125,
        passive_skills: {"arcane_power" => 100}  # +30% max = 130
      )

      character.regenerate_mana!(2)

      # Should cap at 130, not 100
      expect(character.current_mp).to be <= 130
    end
  end

  describe "combined skills" do
    before do
      character.update!(
        max_mp: 100,
        current_mp: 100,
        passive_skills: {
          "arcane_power" => 100,   # +30% max MP = 130
          "spell_mastery" => 100  # -25% mana cost
        }
      )
    end

    it "has increased effective max MP" do
      expect(character.effective_max_mp).to eq(130)
    end

    it "has reduced mana costs" do
      expect(character.reduced_mana_cost(40)).to eq(30)
    end

    it "can cast more spells with the same base mana" do
      # Without skills: 100 mana / 40 cost = 2.5 casts
      # With skills: 130 mana / 30 cost = 4.3 casts
      casts_without = 100 / 40
      casts_with = character.effective_max_mp / character.reduced_mana_cost(40)

      expect(casts_with).to be > casts_without
    end
  end
end

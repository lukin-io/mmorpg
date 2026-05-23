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
    it "returns base max_mp" do
      expect(character.effective_max_mp).to eq(100)
    end

    it "does not apply uncaptured generic max-mana formulas" do
      character.update!(passive_skills: {"fast_mana_regeneration" => 100})

      expect(character.effective_max_mp).to eq(100)
    end
  end

  describe "#reduced_mana_cost" do
    it "returns original cost" do
      expect(character.reduced_mana_cost(20)).to eq(20)
    end

    it "enforces minimum 1 mana cost" do
      expect(character.reduced_mana_cost(0)).to eq(1)
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
  end

  describe "#spend_mana!" do
    it "reduces current_mp by base cost" do
      character.update!(current_mp: 100)

      actual_spent = character.spend_mana!(20)

      expect(actual_spent).to eq(20)
      expect(character.current_mp).to eq(80)
    end

    it "does not go below 0" do
      character.update!(current_mp: 5)

      character.spend_mana!(20)

      expect(character.current_mp).to eq(0)
    end
  end

  describe "#regenerate_mana!" do
    before do
      character.update!(current_mp: 50, max_mp: 100)
    end

    it "regenerates 5% of effective_max_mp per tick" do
      regenerated = character.regenerate_mana!

      expect(regenerated).to eq(5)
      expect(character.current_mp).to eq(55)
    end

    it "regenerates multiple ticks" do
      regenerated = character.regenerate_mana!(3)

      expect(regenerated).to eq(15)
      expect(character.current_mp).to eq(65)
    end

    it "does not exceed effective_max_mp" do
      character.update!(current_mp: 98)

      character.regenerate_mana!(2)

      expect(character.current_mp).to eq(100)
    end
  end
end

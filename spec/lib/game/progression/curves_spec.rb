# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Progression::Curves do
  describe ".xp_to_advance" do
    it "uses the Ashen polynomial with a non-free L0 rung" do
      expect(described_class.xp_to_advance(0)).to eq(160)
      expect(described_class.xp_to_advance(1)).to eq(480)
      expect(described_class.xp_to_advance(9)).to eq(16_000)
    end
  end

  describe ".cumulative_threshold" do
    it "sums advance costs up to the target level" do
      expect(described_class.cumulative_threshold(0)).to eq(0)
      expect(described_class.cumulative_threshold(1)).to eq(160)
      expect(described_class.cumulative_threshold(2)).to eq(640)
      expect(described_class.cumulative_threshold(10)).to eq(55_000)
    end
  end

  describe ".monster_xp" do
    it "scales base monster XP by absolute level gap with a 10% floor" do
      expect(described_class.monster_xp(monster_level: 10, player_level: 10)).to eq(150)
      expect(described_class.monster_xp(monster_level: 1, player_level: 10)).to eq(2)
      expect(described_class.monster_xp(monster_level: 10, player_level: 1)).to eq(15)
    end
  end
end

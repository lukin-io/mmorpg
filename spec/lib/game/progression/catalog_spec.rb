# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Progression::Catalog do
  it "loads contiguous complete Neverlands rows from level zero through 27" do
    expect(described_class.levels.keys).to eq((0..27).to_a)
    expect(described_class.maximum_supported_level).to eq(27)
  end

  it "exposes the exact starter pools and first threshold" do
    expect(described_class.starter).to include(
      "stat_points" => 15,
      "combat_skill_points" => 10,
      "peace_skill_points" => 2,
      "perk_points" => 1
    )
    expect(described_class.experience_threshold_to_reach(1)).to eq(100)
  end

  it "returns nil beyond complete evidence instead of extrapolating" do
    expect(described_class.level(28)).to be_nil
    expect(described_class.experience_threshold_to_reach(28)).to be_nil
  end

  {
    0 => 0, 1 => 100, 2 => 300, 3 => 800, 4 => 1800,
    10 => 50_000, 17 => 25_000_000, 18 => 50_000_000
  }.each do |level, threshold|
    it "accumulates per-level costs to reach level #{level} at #{threshold} XP" do
      expect(described_class.experience_threshold_to_reach(level)).to eq(threshold)
    end
  end

  it "accumulates every complete row without interpreting the current row's cost as a threshold" do
    thresholds = [
      0, 100, 300, 800, 1800, 3500, 5500, 10_000, 18_000, 30_000,
      50_000, 200_000, 500_000, 900_000, 1_600_000, 3_000_000,
      10_000_000, 25_000_000, 50_000_000, 80_000_000, 160_000_000,
      400_000_000, 1_000_000_000, 2_500_000_000, 5_500_000_000,
      10_000_000_000, 16_000_000_000, 25_000_000_000
    ]

    expect((0..27).map { |level| described_class.experience_threshold_to_reach(level) }).to eq(thresholds)
    expect(described_class.level(17).fetch("experience_to_next_level")).to eq(25_000_000)
    expect(described_class.level(27).fetch("experience_to_next_level")).to eq(15_000_000_000)
    expect(described_class.experience_threshold_to_reach(28)).to be_nil
  end

  it "validates positive per-level costs without requiring the costs themselves to increase" do
    entries = described_class.levels.deep_dup
    entries.fetch(1)["experience_to_next_level"] = 100

    expect { described_class.send(:validate!, entries) }.not_to raise_error

    entries.fetch(1)["experience_to_next_level"] = 0
    expect { described_class.send(:validate!, entries) }.to raise_error(/Per-level experience costs must be positive/)
  end

  it "exposes per-fight XP and NPC-count boundaries" do
    expect(described_class.fight_experience_cap(0)).to eq(50)
    expect(described_class.level(10)).to include("fight_experience_cap" => 2500, "max_npcs_in_group" => 4)
  end
end

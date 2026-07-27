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

  it "exposes per-fight XP and NPC-count boundaries" do
    expect(described_class.fight_experience_cap(0)).to eq(50)
    expect(described_class.level(10)).to include("fight_experience_cap" => 2500, "max_npcs_in_group" => 4)
  end
end

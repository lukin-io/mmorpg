# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Progression::Catalog do
  it "loads contiguous Ashen progression rows from level zero through 50" do
    expect(described_class.levels.keys).to eq((0..50).to_a)
    expect(described_class.maximum_supported_level).to eq(50)
  end

  it "exposes denser starter pools and the first threshold" do
    expect(described_class.starter).to include(
      "stat_points" => 20,
      "combat_skill_points" => 12,
      "peace_skill_points" => 3,
      "perk_points" => 1
    )
    expect(described_class.experience_threshold_to_reach(1)).to eq(160)
  end

  it "keeps mid-bracket power gaps material" do
    ten = described_class.experience_threshold_to_reach(10)
    fifteen = described_class.experience_threshold_to_reach(15)
    twenty = described_class.experience_threshold_to_reach(20)

    expect(fifteen).to be > (ten * 3)
    expect(twenty).to be > (fifteen * 2)

    cumul = ->(level, key) {
      (0..level).sum { |row| described_class.level(row).fetch(key) }
    }
    expect(cumul.call(20, "stat_points")).to be >= (cumul.call(10, "stat_points") * 2)
    expect(cumul.call(20, "combat_skill_points")).to be >= (cumul.call(10, "combat_skill_points") * 2)
  end

  it "returns nil beyond the authored table instead of extrapolating" do
    expect(described_class.level(51)).to be_nil
    expect(described_class.experience_threshold_to_reach(51)).to be_nil
  end

  it "exposes growing per-fight XP and NPC-count boundaries" do
    expect(described_class.fight_experience_cap(0)).to eq(22)
    expect(described_class.level(10)).to include("max_npcs_in_group" => 4)
    expect(described_class.fight_experience_cap(30)).to be > described_class.fight_experience_cap(20)
    expect(described_class.fight_experience_cap(50)).to be > described_class.fight_experience_cap(30)
  end
end

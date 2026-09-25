# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::AggroPackSize do
  it "keeps low-level packs in 1..3" do
    expect(described_class.range_for(1)).to eq(1..3)
    expect(described_class.range_for(5)).to eq(1..3)
  end

  it "scales mid packs to 3..5 then higher bands" do
    expect(described_class.range_for(6)).to eq(3..5)
    expect(described_class.range_for(10)).to eq(3..5)
    expect(described_class.range_for(11)).to eq(5..7)
  end

  it "caps high-end packs at MAX_ENCOUNTER_SIZE" do
    range = described_class.range_for(200)
    expect(range.max).to be <= TileNpc::MAX_ENCOUNTER_SIZE
    expect(described_class.new(level: 3, rng: Random.new(1)).call).to be_between(1, 3)
  end
end

RSpec.describe Game::World::NpcLoadout do
  it "maps world tiers onto catalog set tiers" do
    expect(described_class.catalog_tier_for(1)).to eq(5)
    expect(described_class.catalog_tier_for(23)).to eq(50)
  end

  it "keeps set-piece drop chance scarce" do
    expect(described_class.drop_chance_percent(role: "trash", set_tier: 5)).to be <= 2.0
    expect(described_class.drop_chance_percent(role: "boss", set_tier: 50)).to be < 2.0
  end
end

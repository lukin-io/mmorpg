# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Instances::Catalog do
  it "lists dungeon and raid rows from gameplay JSON" do
    expect(described_class.dungeons.size).to be >= 1
    expect(described_class.raids.size).to be >= 1
    row = described_class.dungeons.first
    expect(row.id).to be_present
    expect(row.kind).to eq("dungeon")
    expect(row.name).to be_present
  end
end

RSpec.describe Game::Catalog::ShopTiering do
  it "maps rarity to 23-tier shop availability" do
    expect(described_class.tier_for("common")).to eq(1)
    expect(described_class.tier_for("donor")).to eq(23)
    expect(described_class.shop_entry(rarity: "epic", position: 3)).to include(
      "sold" => true,
      "tier" => 10,
      "min_level" => 10
    )
  end
end

RSpec.describe Game::Activity::Tracker do
  let(:character) { create(:character) }

  it "creates daily contracts and bumps achievement progress" do
    described_class.new(character:).record!(kind: "kill_npc", amount: 3)

    day = Time.current.utc.strftime("%Y-%m-%d")
    expect(DailyActivityContract.where(character:, day_key: day).count).to eq(4)
    expect(ActivityAchievement.where(character:).sum(:progress)).to be >= 3
  end
end

RSpec.describe Game::Idle::ControlledTicker do
  it "arms, runs once, and disarms" do
    ticker = described_class.new
    expect(ticker.arm![:armed]).to eq(true)
    result = ticker.run_once!(batch: 1)
    expect(result[:ran]).to be >= 0
    expect(ticker.disarm![:armed]).to eq(false)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Economy::MistCurve do
  describe ".craft_sell_bonus" do
    it "returns 1.15 for seasonal craft demand keys while the season is active" do
      allow(Game::Seasons::Catalog).to receive(:active?).and_return(true)
      allow(Game::Seasons::Catalog).to receive(:current).and_return(
        "craft_demand_keys" => %w[pine_resin ash_herb coal_chunk]
      )

      expect(described_class.craft_sell_bonus("pine_resin")).to eq(1.15)
      expect(described_class.craft_sell_bonus("iron_ore")).to eq(1.0)
    end

    it "returns 1.0 when the season is inactive" do
      allow(Game::Seasons::Catalog).to receive(:active?).and_return(false)

      expect(described_class.craft_sell_bonus("pine_resin")).to eq(1.0)
    end
  end

  describe "ResourceExchange coupling" do
    it "stacks season demand with craft bonus on sell_price" do
      allow(Game::Seasons::Catalog).to receive(:active?).and_return(true)
      allow(Game::Seasons::Catalog).to receive(:demand_multiplier).and_return(1.25)
      allow(described_class).to receive(:craft_sell_bonus).and_return(1.15)

      # gov coal = 20 → 20 * 1.25 * 1.15 = 28.75 → 29
      expect(Game::World::ResourceExchange.sell_price("coal_chunk")).to eq(29)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::LootEntry do
  describe "#chance_percent" do
    it "normalizes an explicit fractional chance" do
      entry = described_class.new({"kind" => "item", "chance" => 0.25})

      expect(entry.chance_percent).to eq(25.0)
    end

    it "retains an explicit percentage chance" do
      entry = described_class.new({"kind" => "currency", "chance" => 24})

      expect(entry.chance_percent).to eq(24.0)
    end

    it "rejects a missing chance" do
      expect {
        described_class.new({"kind" => "item"})
      }.to raise_error(described_class::InvalidError, "Loot chance is required")
    end

    it "rejects an out-of-range chance" do
      expect {
        described_class.new({"kind" => "item", "chance" => 101})
      }.to raise_error(described_class::InvalidError, "Loot chance must be between 0 and 100")
    end
  end
end

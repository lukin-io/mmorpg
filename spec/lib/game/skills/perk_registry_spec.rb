# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PerkRegistry do
  describe ".all" do
    it "exposes only the named live-captured starter perk" do
      expect(described_class.all.keys).to eq([:more_strength])
      expect(described_class.find(:more_strength)).to include(
        source_id: 7,
        name: "More Strength",
        source_name: "Больше силы",
        category: :stat
      )
    end
  end

  describe ".find_by_source_id" do
    it "looks up captured perks by Neverlands id" do
      expect(described_class.find_by_source_id(7)[:key]).to eq(:more_strength)
      expect(described_class.find_by_source_id(999)).to be_nil
    end
  end

  describe ".excluded_source_ids_for" do
    it "retains the captured branch exclusion table without exposing unnamed perks" do
      expect(described_class.excluded_source_ids_for(24)).to eq([27, 19, 38, 14, 40, 39, 32, 5, 41])
      expect(described_class.excluded_source_ids_for(5)).to eq([24, 25, 26, 27, 19, 38, 14, 40, 39, 32])
      expect(described_class.excluded_source_ids_for(7)).to eq([])
    end
  end
end

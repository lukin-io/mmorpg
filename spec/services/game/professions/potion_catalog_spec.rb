# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Professions::PotionCatalog do
  it "defines blood-tiered potions with level gates and 1h buffs" do
    expect(described_class::POTIONS.size).to be >= 18
    described_class::POTIONS.each do |key, row|
      expect(row[:blood]).to be_between(1, 3)
      expect(row[:level]).to be >= 1
      expect(row[:mods]).to be_a(Hash)
      expect(row[:price]).to be > 0
      expect(described_class.shop_price(key)).to be > row[:price]
    end
  end

  it "ensures potion templates with requirements and buff payload" do
    described_class.ensure_templates!
    template = ItemTemplate.find_by!(key: "blood3_warlord_elixir")
    expect(template.requirements["level"]).to eq(22)
    expect(template.stat_modifiers["buff_duration_seconds"]).to eq(3600)
    expect(template.stat_modifiers.dig("buff", "attack")).to eq(22)
  end

  it "merges potion recipes into the profession catalog" do
    expect(Game::Professions::Catalog.recipe("blood2_war_draught")).to be_present
    expect(Game::Professions::Catalog.recipe("blood3_veil_ascendant").dig("output", "item_key")).to eq("blood3_veil_ascendant")
  end
end

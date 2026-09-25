# frozen_string_literal: true

require "rails_helper"

RSpec.describe InventoriesHelper, type: :helper do
  describe "#item_artwork_path" do
    it "selects the original illustration by the authored item key" do
      %w[penknife hunter_knife mage_dagger small_crescent_staff subtlety_ring knowledge_shirt duel_permit_i].each do |key|
        template = build_stubbed(:item_template, key:, name: "Translated item name")

        expect(helper.item_artwork_path(template)).to eq("items/#{key}.png")
      end
    end

    it "leaves unknown or absent keys to the existing visual fallback" do
      [nil, "", "uncaptured_knife", "../penknife", "items/penknife.png"].each do |key|
        template = build_stubbed(:item_template, key:, name: "Penknife")

        expect(helper.item_artwork_path(template)).to be_nil
      end
    end
  end

  describe "#equipment_comparison_rows" do
    it "shows compact shop, craft, and premium tiers for crafted gear" do
      template = build_stubbed(:item_template, key: "ash_ranger_jacket", item_type: "equipment", base_price: 276)

      expect(helper.equipment_comparison_rows(template)).to include(
        [I18n.t("game.details.compare_craft"), "276 NV · 100%"]
      )
      expect(helper.equipment_comparison_rows(template).map(&:first)).to contain_exactly(
        I18n.t("game.details.compare_shop"),
        I18n.t("game.details.compare_craft"),
        I18n.t("game.details.compare_premium")
      )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe InventoriesHelper, type: :helper do
  describe "#item_artwork_dimensions" do
    it "uses the paper-doll geometry for every wearable, including slot aliases" do
      EquipmentSlots::ORDERED.each do |slot|
        template = build_stubbed(:item_template, item_type: "equipment", slot: slot.key)
        expect(helper.item_artwork_dimensions(template)).to eq(width: slot.width, height: slot.height)
      end
      {"necklace" => [62, 35], "ring" => [31, 31], "shield" => [62, 91]}.each do |slot, (width, height)|
        template = build_stubbed(:item_template, item_type: "equipment", slot:)
        expect(helper.item_artwork_dimensions(template)).to eq(width:, height:)
      end
    end

    it "keeps the captured permit footprint separate from other consumables" do
      %w[duel_permit_i duel_permit_ii duel_permit_iii duel_permit_iv].each do |key|
        template = build_stubbed(:item_template, key:, item_type: "consumable", slot: "none")
        expect(helper.item_artwork_dimensions(template)).to eq(width: 42, height: 21)
      end
      template = build_stubbed(:item_template, key: "minor_health_potion", item_type: "consumable", slot: "none")
      expect(helper.item_artwork_dimensions(template)).to eq(width: 60, height: 60)
    end
  end

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
end

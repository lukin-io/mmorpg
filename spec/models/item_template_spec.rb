# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemTemplate, type: :model do
  describe "validations" do
    it "requires name to be present" do
      template = build(:item_template, name: nil)
      expect(template).not_to be_valid
    end

    it "requires name to be unique" do
      create(:item_template, name: "Unique Sword")
      template = build(:item_template, name: "Unique Sword")
      expect(template).not_to be_valid
    end

    it "requires slot to be present" do
      template = build(:item_template, slot: nil)
      expect(template).not_to be_valid
    end

    it "requires rarity to be present" do
      template = build(:item_template, rarity: nil)
      expect(template).not_to be_valid
    end

    it "requires weight to be greater than 0" do
      template = build(:item_template, weight: 0)
      expect(template).not_to be_valid
    end

    it "requires stack_limit to be greater than 0" do
      template = build(:item_template, stack_limit: 0)
      expect(template).not_to be_valid
    end

    it "validates rarity is in allowed list" do
      template = build(:item_template, rarity: "mythic")
      expect(template).not_to be_valid
      expect(template.errors[:rarity]).to include("is not included in the list")
    end

    it "validates stat_modifiers presence for equipment items" do
      template = build(:item_template, item_type: "equipment", stat_modifiers: nil)
      expect(template).not_to be_valid
    end

    it "does not require stat_modifiers for materials" do
      template = build(:item_template, :material)
      expect(template).to be_valid
    end
  end

  describe "scopes" do
    let!(:equipment) { create(:item_template, item_type: "equipment") }
    let!(:material) { create(:item_template, :material, name: "Iron Ore") }
    let!(:consumable) { create(:item_template, :consumable, name: "Potion") }

    describe ".materials" do
      it "returns only materials" do
        expect(described_class.materials).to contain_exactly(material)
      end
    end

    describe ".equipment" do
      it "returns only equipment" do
        expect(described_class.equipment).to contain_exactly(equipment)
      end
    end

    describe ".consumables" do
      it "returns only consumables" do
        expect(described_class.consumables).to contain_exactly(consumable)
      end
    end
  end

  describe "#material?" do
    it "returns true for materials" do
      template = build(:item_template, :material)
      expect(template.material?).to be true
    end

    it "returns false for equipment" do
      template = build(:item_template, item_type: "equipment")
      expect(template.material?).to be false
    end
  end

  describe "#equipment?" do
    it "returns true for equipment items" do
      template = build(:item_template, item_type: "equipment")
      expect(template.equipment?).to be true
    end

    it "returns true when item_type is nil" do
      template = build(:item_template, item_type: nil)
      expect(template.equipment?).to be true
    end

    it "returns false for materials" do
      template = build(:item_template, :material)
      expect(template.equipment?).to be false
    end
  end

  describe "#consumable?" do
    it "returns true for consumables" do
      template = build(:item_template, :consumable)
      expect(template.consumable?).to be true
    end

    it "returns false for equipment" do
      template = build(:item_template, item_type: "equipment")
      expect(template.consumable?).to be false
    end
  end

  describe "#equippable?" do
    it "returns true for equipment with valid slot" do
      template = build(:item_template, item_type: "equipment", slot: "main_hand")
      expect(template.equippable?).to be true
    end

    it "returns false for materials" do
      template = build(:item_template, :material)
      expect(template.equippable?).to be false
    end

    it "returns false for consumables" do
      template = build(:item_template, :consumable)
      expect(template.equippable?).to be false
    end

    it "returns false for equipment with invalid slot" do
      template = build(:item_template, item_type: "equipment", slot: "invalid_slot")
      expect(template.equippable?).to be false
    end

    ItemTemplate::EQUIPMENT_SLOTS.each do |slot|
      it "returns true for equipment with #{slot} slot" do
        template = build(:item_template, item_type: "equipment", slot: slot)
        expect(template.equippable?).to be true
      end
    end
  end

  describe "#equipment_slot" do
    it "returns the slot value for equipment" do
      template = build(:item_template, item_type: "equipment", slot: "chest")
      expect(template.equipment_slot).to eq("chest")
    end

    it "returns nil for non-equipment" do
      template = build(:item_template, :material)
      expect(template.equipment_slot).to be_nil
    end
  end

  describe "premium stat cap validation" do
    context "when item is premium" do
      it "allows total stats up to 10" do
        template = build(:item_template, premium: true, slot: "main_hand",
          stat_modifiers: {"attack" => 5, "defense" => 5})
        expect(template).to be_valid
      end

      it "rejects total stats over 10" do
        template = build(:item_template, premium: true, slot: "main_hand",
          stat_modifiers: {"attack" => 10, "defense" => 5})
        expect(template).not_to be_valid
        expect(template.errors[:stat_modifiers]).to include("premium artifacts must stay cosmetic-balanced")
      end
    end

    context "when item is not premium" do
      it "allows any stat totals" do
        template = build(:item_template, premium: false, slot: "main_hand",
          stat_modifiers: {"attack" => 50, "defense" => 30})
        expect(template).to be_valid
      end
    end
  end
end

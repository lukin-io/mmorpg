# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory, type: :model do
  let(:character) { create(:character) }
  let(:inventory) { character.inventory }

  describe "associations" do
    it "belongs to character" do
      expect(inventory.character).to eq(character)
    end

    it "has many inventory_items" do
      expect(inventory).to respond_to(:inventory_items)
    end
  end

  describe "validations" do
    it "requires slot_capacity to be greater than 0" do
      inventory.slot_capacity = 0
      expect(inventory).not_to be_valid
    end

    it "requires weight_capacity to be greater than 0" do
      inventory.weight_capacity = 0
      expect(inventory).not_to be_valid
    end

    it "requires current_weight to be >= 0" do
      inventory.current_weight = -1
      expect(inventory).not_to be_valid
    end
  end

  describe "#max_slots" do
    it "returns the slot_capacity value" do
      inventory.update!(slot_capacity: 50)
      expect(inventory.max_slots).to eq(50)
    end
  end

  describe "#max_weight" do
    it "returns the weight_capacity value" do
      inventory.update!(weight_capacity: 200)
      expect(inventory.max_weight).to eq(200)
    end
  end

  describe "#material_count" do
    let(:iron_ore) { create(:item_template, :material, name: "Iron Ore") }

    it "returns 0 when no materials present" do
      expect(inventory.material_count("Iron Ore")).to eq(0)
    end

    it "returns the sum of quantities for matching items" do
      create(:inventory_item, inventory: inventory, item_template: iron_ore, quantity: 5)
      create(:inventory_item, inventory: inventory, item_template: iron_ore, quantity: 3)

      expect(inventory.material_count("Iron Ore")).to eq(8)
    end
  end

  describe "#materials_available?" do
    let(:iron_ore) { create(:item_template, :material, name: "Iron Ore") }
    let(:coal) { create(:item_template, :material, name: "Coal") }

    before do
      create(:inventory_item, inventory: inventory, item_template: iron_ore, quantity: 10)
      create(:inventory_item, inventory: inventory, item_template: coal, quantity: 5)
    end

    it "returns true when all materials are available" do
      expect(inventory.materials_available?({"Iron Ore" => 5, "Coal" => 3})).to be true
    end

    it "returns false when a material is insufficient" do
      expect(inventory.materials_available?({"Iron Ore" => 5, "Coal" => 10})).to be false
    end

    it "returns false when a material is missing" do
      expect(inventory.materials_available?({"Iron Ore" => 5, "Gold" => 1})).to be false
    end
  end

  describe "#consume_materials!" do
    let(:iron_ore) { create(:item_template, :material, name: "Iron Ore") }

    before do
      create(:inventory_item, inventory: inventory, item_template: iron_ore, quantity: 10)
    end

    it "decreases material quantities" do
      inventory.consume_materials!({"Iron Ore" => 3})

      expect(inventory.material_count("Iron Ore")).to eq(7)
    end

    it "removes items when quantity reaches zero" do
      inventory.consume_materials!({"Iron Ore" => 10})

      expect(inventory.inventory_items.count).to eq(0)
    end

    it "raises error when insufficient materials" do
      expect {
        inventory.consume_materials!({"Iron Ore" => 15})
      }.to raise_error(Inventory::InsufficientMaterialsError, /Missing Iron Ore/)
    end
  end

  describe "#add_item_by_name!" do
    let!(:iron_ore) { create(:item_template, :material, name: "Iron Ore") }

    it "adds a new item to inventory" do
      # Ensure starting from 0
      expect(inventory.material_count("Iron Ore")).to eq(0)

      inventory.add_item_by_name!("Iron Ore", quantity: 5)

      expect(inventory.material_count("Iron Ore")).to eq(5)
      expect(inventory.inventory_items.where(item_template: iron_ore).count).to eq(1)
    end

    it "stacks with existing items" do
      create(:inventory_item, inventory: inventory, item_template: iron_ore, quantity: 3)

      inventory.add_item_by_name!("Iron Ore", quantity: 5)

      expect(inventory.material_count("Iron Ore")).to eq(8)
    end
  end
end

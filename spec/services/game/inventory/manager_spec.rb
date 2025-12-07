# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Inventory::Manager do
  let(:character) { create(:character) }
  # Use the inventory created by the character factory, update its capacity
  let(:inventory) do
    inv = character.inventory
    inv.update!(slot_capacity: 20, weight_capacity: 100, current_weight: 0)
    inv
  end
  let(:item_template) { create(:item_template, name: "Iron Ore", weight: 1, stack_limit: 99) }

  subject(:manager) { described_class.new(inventory: inventory) }

  describe "#add_item!" do
    context "when adding to empty inventory" do
      it "creates a new stack with the correct quantity" do
        manager.add_item!(item_template: item_template, quantity: 5)

        expect(inventory.inventory_items.count).to eq(1)
        expect(inventory.inventory_items.first.quantity).to eq(5)
      end

      it "returns the created inventory item" do
        result = manager.add_item!(item_template: item_template, quantity: 3)

        expect(result).to be_a(InventoryItem)
        expect(result.quantity).to eq(3)
        expect(result).to be_persisted
      end

      it "increments inventory weight" do
        manager.add_item!(item_template: item_template, quantity: 5)

        expect(inventory.reload.current_weight).to eq(5)
      end

      # Regression test: Bug fix for quantity: 0 validation error
      # The manager previously tried to create items with quantity: 0 then increment,
      # but InventoryItem validates quantity > 0, causing validation failure.
      it "does not fail with 'Quantity must be greater than 0' validation" do
        expect {
          manager.add_item!(item_template: item_template, quantity: 1)
        }.not_to raise_error
      end

      it "creates item with correct quantity even for quantity: 1" do
        result = manager.add_item!(item_template: item_template, quantity: 1)

        expect(result.quantity).to eq(1)
        expect(result).to be_persisted
      end

      it "can add multiple items in sequence" do
        manager.add_item!(item_template: item_template, quantity: 3)
        manager.add_item!(item_template: item_template, quantity: 5)

        expect(inventory.inventory_items.count).to eq(1)
        expect(inventory.inventory_items.first.quantity).to eq(8)
      end
    end

    context "when adding to existing stack" do
      let!(:existing_item) do
        inventory.inventory_items.create!(
          item_template: item_template,
          quantity: 10,
          weight: item_template.weight
        )
      end

      it "increments the existing stack" do
        manager.add_item!(item_template: item_template, quantity: 5)

        expect(inventory.inventory_items.count).to eq(1)
        expect(existing_item.reload.quantity).to eq(15)
      end
    end

    context "when stack limit is reached" do
      let(:small_stack_item) { create(:item_template, name: "Potion", weight: 0.5, stack_limit: 10) }
      let!(:full_stack) do
        inventory.inventory_items.create!(
          item_template: small_stack_item,
          quantity: 10,
          weight: small_stack_item.weight
        )
      end

      it "creates a new stack when existing is full" do
        manager.add_item!(item_template: small_stack_item, quantity: 5)

        expect(inventory.inventory_items.count).to eq(2)
        expect(full_stack.reload.quantity).to eq(10) # Unchanged
        expect(inventory.inventory_items.last.quantity).to eq(5)
      end
    end

    context "when inventory is full" do
      before do
        inventory.update!(slot_capacity: 1)
        inventory.inventory_items.create!(
          item_template: item_template,
          quantity: item_template.stack_limit,
          weight: item_template.weight
        )
      end

      it "raises CapacityExceededError" do
        expect {
          manager.add_item!(item_template: item_template, quantity: 1)
        }.to raise_error(Game::Inventory::Manager::CapacityExceededError)
      end
    end

    context "when weight limit would be exceeded" do
      let(:heavy_item) { create(:item_template, name: "Boulder", weight: 50, stack_limit: 10) }

      before do
        inventory.update!(weight_capacity: 60, current_weight: 50)
      end

      it "raises CapacityExceededError" do
        expect {
          manager.add_item!(item_template: heavy_item, quantity: 1)
        }.to raise_error(Game::Inventory::Manager::CapacityExceededError, "Inventory overweight")
      end
    end
  end

  describe "#remove_item!" do
    let!(:existing_item) do
      inventory.inventory_items.create!(
        item_template: item_template,
        quantity: 10,
        weight: item_template.weight
      )
    end

    before do
      inventory.update!(current_weight: 10)
    end

    it "decrements the stack quantity" do
      manager.remove_item!(item_template: item_template, quantity: 3)

      expect(existing_item.reload.quantity).to eq(7)
    end

    it "decrements inventory weight" do
      manager.remove_item!(item_template: item_template, quantity: 3)

      expect(inventory.reload.current_weight).to eq(7)
    end

    it "destroys the stack when quantity reaches zero" do
      manager.remove_item!(item_template: item_template, quantity: 10)

      expect(inventory.inventory_items.count).to eq(0)
    end

    it "raises error when not enough items" do
      expect {
        manager.remove_item!(item_template: item_template, quantity: 15)
      }.to raise_error(Game::Inventory::Manager::InventoryUnderflowError)
    end
  end
end

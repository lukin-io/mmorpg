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
  let(:item_template) { create(:item_template, :material, name: "Wood Chips", weight: 1, stack_limit: 99) }

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
      let(:small_stack_item) { create(:item_template, :consumable, name: "Potion", weight: 1, stack_limit: 10) }
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

    context "when many distinct stacks already exist" do
      before do
        inventory.update!(slot_capacity: 1)
        inventory.inventory_items.create!(
          item_template: item_template,
          quantity: item_template.stack_limit,
          weight: item_template.weight
        )
      end

      it "still accepts a new stack without a hard slot limit" do
        other = create(:item_template, :material, name: "Extra chips", weight: 1, stack_limit: 10)

        expect {
          manager.add_item!(item_template: other, quantity: 1)
        }.not_to raise_error

        expect(inventory.inventory_items.count).to eq(2)
      end
    end

    context "when only part of a multi-stack quantity fits prior stacks" do
      let(:small_stack_item) do
        create(:item_template, :material, name: "Small stack loot", weight: 1, stack_limit: 10)
      end
      let!(:partial_stack) do
        inventory.inventory_items.create!(
          item_template: small_stack_item,
          quantity: 8,
          weight: small_stack_item.weight
        )
      end

      before do
        inventory.update!(slot_capacity: 1, current_weight: 8)
      end

      it "opens another stack when the existing stack is full" do
        manager.add_item!(item_template: small_stack_item, quantity: 5)

        expect(partial_stack.reload.quantity).to eq(10)
        expect(inventory.reload.current_weight).to eq(13)
        expect(inventory.inventory_items.where(item_template: small_stack_item).count).to eq(2)
      end
    end

    context "when carried mass exceeds the soft capacity" do
      let(:heavy_item) { create(:item_template, :material, name: "Heavy Wood Chips", weight: 50, stack_limit: 10) }

      before do
        inventory.update!(weight_capacity: 60, current_weight: 50)
        allow(inventory).to receive(:max_weight).and_return(60)
      end

      it "still adds the item and records overweight mass" do
        expect {
          manager.add_item!(item_template: heavy_item, quantity: 1)
        }.not_to raise_error

        expect(inventory.reload.current_weight).to eq(100)
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

  describe ".use_item" do
    it "consumes a potion and applies its timed buff instead of instant healing" do
      Game::Professions::Templates.ensure_craft_items!
      potion = ItemTemplate.find_by!(key: "strength_brew")
      item = manager.add_item!(item_template: potion, quantity: 1)
      character.update!(current_hp: 1)

      result = described_class.use_item(character, item)

      expect(result[:success]).to be(true)
      expect(character.reload.current_hp).to eq(1)
      expect(Game::Characters::TimedBuffs.new(character:).modifier("attack")).to eq(8)
      expect(item).to be_destroyed
    end
  end
end

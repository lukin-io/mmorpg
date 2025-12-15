# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventories", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:inventory) { character.inventory }

  before do
    sign_in user, scope: :user
    # Ensure character is set as active
    allow_any_instance_of(InventoriesController).to receive(:current_character).and_return(character)
    allow_any_instance_of(InventoryItemsController).to receive(:current_character).and_return(character)
  end

  describe "GET /inventory" do
    it "returns a successful response" do
      get inventory_path

      expect(response).to have_http_status(:success)
    end

    it "displays inventory slots and weight" do
      get inventory_path

      expect(response.body).to include("Inventory")
      expect(response.body).to include("Bag")
    end

    context "with items in inventory" do
      let(:item_template) { create(:item_template, name: "Test Sword", item_type: "equipment", slot: "main_hand") }
      let!(:inventory_item) { create(:inventory_item, inventory: inventory, item_template: item_template) }

      it "displays items in the grid" do
        get inventory_path

        expect(response.body).to include("Test Sword")
      end
    end
  end

  describe "POST /inventory/equip" do
    let(:item_template) do
      create(:item_template, name: "Iron Sword", item_type: "equipment", slot: "main_hand",
                             stat_modifiers: {attack: 10})
    end
    let!(:inventory_item) do
      create(:inventory_item, inventory: inventory, item_template: item_template, equipped: false)
    end

    it "equips the item" do
      post equip_inventory_path, params: {item_id: inventory_item.id}

      expect(response).to redirect_to(inventory_path).or have_http_status(:success)
      expect(inventory_item.reload.equipped).to be true
    end

    context "with turbo_stream format" do
      it "returns turbo stream response" do
        post equip_inventory_path, params: {item_id: inventory_item.id},
                                   headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /inventory/unequip" do
    let(:item_template) do
      create(:item_template, name: "Iron Sword", item_type: "equipment", slot: "main_hand")
    end
    let!(:inventory_item) do
      create(:inventory_item, inventory: inventory, item_template: item_template,
                              equipped: true, equipment_slot: :main_hand)
    end

    it "unequips the item" do
      post unequip_inventory_path, params: {slot: "main_hand"}

      expect(response).to redirect_to(inventory_path).or have_http_status(:success)
      expect(inventory_item.reload.equipped).to be false
    end
  end

  describe "POST /inventory/use" do
    let(:item_template) do
      create(:item_template, name: "Health Potion", item_type: "consumable", slot: "none",
                             stat_modifiers: {"heal_hp" => 50}, stack_limit: 99)
    end
    let!(:inventory_item) do
      create(:inventory_item, inventory: inventory, item_template: item_template, quantity: 3)
    end

    before do
      character.update!(current_hp: 50, max_hp: 100)
    end

    it "uses the consumable and decreases quantity" do
      expect {
        post use_inventory_path, params: {item_id: inventory_item.id}
      }.to change { inventory_item.reload.quantity }.by(-1)

      expect(response).to redirect_to(inventory_path)
    end

    it "heals the character" do
      post use_inventory_path, params: {item_id: inventory_item.id}

      expect(character.reload.current_hp).to be > 50
    end
  end

  describe "POST /inventory/sort" do
    let(:sword_template) { create(:item_template, name: "Sword", item_type: "equipment", slot: "main_hand") }
    let(:potion_template) { create(:item_template, name: "Potion", item_type: "consumable", slot: "none", stat_modifiers: {"heal_hp" => 10}) }
    let!(:item1) { create(:inventory_item, inventory: inventory, item_template: potion_template) }
    let!(:item2) { create(:inventory_item, inventory: inventory, item_template: sword_template) }

    it "sorts inventory by type" do
      post sort_inventory_path, params: {sort_type: "type"}

      expect(response).to redirect_to(inventory_path)
    end

    it "sorts inventory by rarity" do
      post sort_inventory_path, params: {sort_type: "rarity"}

      expect(response).to redirect_to(inventory_path)
    end
  end

  describe "DELETE /inventory/items/:id" do
    let(:item_template) { create(:item_template, name: "Junk Item") }
    let!(:inventory_item) { create(:inventory_item, inventory: inventory, item_template: item_template) }

    it "removes the item from inventory" do
      expect {
        delete inventory_item_path(inventory_item)
      }.to change { inventory.inventory_items.count }.by(-1)

      expect(response).to redirect_to(inventory_path)
    end
  end
end

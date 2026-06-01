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
      let(:item_template) { create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand") }
      let!(:inventory_item) { create(:inventory_item, inventory: inventory, item_template: item_template) }

      it "displays items in the grid" do
        get inventory_path

        expect(response.body).to include("Pocket Knife")
      end
    end

    it "renders Neverlands inventory family empty states" do
      get inventory_path(category: "alchemy")

      expect(response.body).to include("Alchemy Inventory")
      expect(response.body).to include("Alchemy Resources")
      expect(response.body).to include("No alchemy inventory items available.")
    end

    it "shows unmet requirements and hides wear action" do
      item_template = create(:item_template, name: "Mage Dagger", item_type: "equipment", slot: "main_hand",
        requirements: {"knowledge" => 15})
      create(:inventory_item, inventory: inventory, item_template: item_template)

      get inventory_path

      expect(response.body).to include("Mage Dagger")
      expect(response.body).to include("Requirements not met")
      expect(response.body).not_to include("Wear")
    end

    it "flattens nested Neverlands-style stat and skill requirements" do
      item_template = create(:item_template, name: "Hunter Knife", item_type: "equipment", slot: "main_hand",
        requirements: {"stats" => {"knowledge" => 15}, "skills" => {"knife_skill" => 10}})
      create(:inventory_item, inventory: inventory, item_template: item_template)

      get inventory_path

      expect(response.body).to include("Hunter Knife")
      expect(response.body).to include("Knowledge")
      expect(response.body).to include("Knife Skill")
      expect(response.body).to include("current 0")
    end

    it "renders equipped items only in the equipment doll, not as carried rows" do
      item_template = create(:item_template, name: "Knowledge Ring", item_type: "equipment", slot: "ring",
        stat_modifiers: {"knowledge" => 3})
      create(:inventory_item, inventory: inventory, item_template: item_template,
        equipped: true, equipment_slot: "ring_1")

      get inventory_path

      expect(response.body.scan("Knowledge Ring").size).to eq(1)
      expect(response.body).to include("Remove all gear")
    end

    it "does not show bulk unequip when no items are equipped" do
      get inventory_path

      expect(response.body).not_to include("Remove all gear")
    end
  end

  describe "POST /inventory/equip" do
    let(:item_template) do
      create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand",
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

    it "rejects equipment when item requirements are not met" do
      item_template.update!(requirements: {"level" => character.level + 1})

      post equip_inventory_path, params: {item_id: inventory_item.id}

      expect(response).to redirect_to(inventory_path)
      expect(inventory_item.reload.equipped).to be false
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
      create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand")
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

    it "removes an explicit two-handed weapon from the off-hand occupied slot" do
      item_template.update!(slot: "two_handed", enhancement_rules: {"two_handed" => true})
      inventory_item.update!(equipped: true, equipment_slot: "main_hand")

      post unequip_inventory_path, params: {slot: "off_hand"}

      expect(response).to redirect_to(inventory_path).or have_http_status(:success)
      expect(inventory_item.reload.equipped).to be false
    end
  end

  describe "POST /inventory/unequip_all" do
    let(:ring_template) { create(:item_template, name: "Knowledge Ring", item_type: "equipment", slot: "ring", stat_modifiers: {"knowledge" => 3}) }
    let(:knife_template) { create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand") }
    let!(:ring) { create(:inventory_item, inventory: inventory, item_template: ring_template, equipped: true, equipment_slot: "ring_1") }
    let!(:knife) { create(:inventory_item, inventory: inventory, item_template: knife_template, equipped: true, equipment_slot: "main_hand") }

    it "removes all equipped items without changing carried weight" do
      inventory.update!(current_weight: 3)

      post unequip_all_inventory_path

      expect(response).to redirect_to(inventory_path)
      expect(ring.reload.equipped).to be false
      expect(knife.reload.equipped).to be false
      expect(inventory.reload.current_weight).to eq(3)
    end
  end

  describe "equipment sets" do
    let(:ring_template) { create(:item_template, name: "Knowledge Ring", item_type: "equipment", slot: "ring", stat_modifiers: {"knowledge" => 3}) }
    let!(:ring) { create(:inventory_item, inventory: inventory, item_template: ring_template, equipped: true, equipment_slot: "ring_1") }

    it "saves, wears, and deletes a named equipment set" do
      post save_equipment_set_inventory_path, params: {set_name: "magic"}
      expect(inventory.reload.metadata.dig("equipment_sets", "magic", "slots", "ring_1")).to eq(ring.id)

      ring.update!(equipped: false, equipment_slot: nil)
      post wear_equipment_set_inventory_path, params: {set_name: "magic"}
      expect(ring.reload.equipped).to be true
      expect(ring.equipment_slot).to eq("ring_1")

      delete delete_equipment_set_inventory_path, params: {set_name: "magic"}
      expect(inventory.reload.metadata.fetch("equipment_sets", {})).not_to have_key("magic")
    end
  end

  describe "POST /inventory/use" do
    let(:item_template) do
      create(:item_template, name: "Life Potion", item_type: "consumable", slot: "none",
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

    it "uses durability charges before removing a consumable" do
      item_template.update!(durability_max: 2)
      inventory_item.update!(quantity: 1, properties: {"current_durability" => 2})

      expect {
        post use_inventory_path, params: {item_id: inventory_item.id}
      }.not_to change { inventory.inventory_items.count }

      expect(inventory_item.reload.current_durability).to eq(1)
    end

    it "resets allocated stats and skills for reset scrolls" do
      item_template.update!(name: "Reset Scroll", stat_modifiers: {"reset_allocation" => true}, requirements: {})
      character.update!(
        allocated_stats: {"strength" => 2},
        passive_skills: {"knife_mastery" => 8},
        stat_points_available: 0,
        combat_skill_points: 0
      )

      post use_inventory_path, params: {item_id: inventory_item.id}

      expect(character.reload.allocated_stats).to eq({})
      expect(character.passive_skills).to eq({})
      expect(character.stat_points_available).to eq(2)
      expect(character.combat_skill_points).to eq(1)
    end
  end

  describe "direct inventory transfer actions" do
    let(:recipient_user) { create(:user) }
    let(:recipient) { create(:character, user: recipient_user, name: "receiver") }
    let(:item_template) { create(:item_template, :material, name: "Rat Tail", weight: 1, stack_limit: 99) }
    let!(:inventory_item) { create(:inventory_item, inventory: inventory, item_template: item_template, quantity: 2, weight: 1) }

    before do
      recipient.inventory.update!(slot_capacity: 5, weight_capacity: 10, current_weight: 0)
      inventory.update!(current_weight: 2)
    end

    it "transfers an item stack quantity to another character" do
      post transfer_item_inventory_path, params: {item_id: inventory_item.id, recipient_name: "receiver", quantity: 1}

      expect(response).to redirect_to(inventory_path)
      expect(inventory_item.reload.quantity).to eq(1)
      expect(recipient.inventory.inventory_items.find_by(item_template:).quantity).to eq(1)
      expect(inventory.reload.current_weight).to eq(1)
      expect(recipient.inventory.reload.current_weight).to eq(1)
    end

    it "transfers NV to another character wallet" do
      user.currency_wallet.update!(nv_balance: 50)
      recipient_user.currency_wallet.update!(nv_balance: 0)

      post transfer_money_inventory_path, params: {recipient_name: "receiver", amount: "12.50"}

      expect(user.currency_wallet.reload.nv_balance).to eq(37.5)
      expect(recipient_user.currency_wallet.reload.nv_balance).to eq(12.5)
    end

    it "sells an item to another player with decimal NV settlement" do
      inventory.update!(metadata: {"trade_license" => true})
      user.currency_wallet.update!(nv_balance: 0)
      recipient_user.currency_wallet.update!(nv_balance: 12.75)

      post sell_to_player_inventory_path, params: {
        item_id: inventory_item.id,
        recipient_name: "receiver",
        quantity: 1,
        price: "12.50"
      }

      expect(response).to redirect_to(inventory_path)
      expect(user.currency_wallet.reload.nv_balance).to eq(12.5)
      expect(recipient_user.currency_wallet.reload.nv_balance).to eq(0.25)
      expect(recipient.inventory.inventory_items.find_by(item_template:).quantity).to eq(1)
    end
  end

  describe "POST /inventory/sort" do
    let(:sword_template) { create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand") }
    let(:potion_template) { create(:item_template, name: "Life Potion", item_type: "consumable", slot: "none", stat_modifiers: {"heal_hp" => 10}) }
    let!(:item1) { create(:inventory_item, inventory: inventory, item_template: potion_template) }
    let!(:item2) { create(:inventory_item, inventory: inventory, item_template: sword_template) }

    it "sorts inventory by type" do
      post sort_inventory_path, params: {sort_type: "type"}

      expect(response).to redirect_to(inventory_path)
    end

    it "sorts inventory by name" do
      post sort_inventory_path, params: {sort_type: "name"}

      expect(response).to redirect_to(inventory_path)
    end
  end

  describe "DELETE /inventory/items/:id" do
    let(:item_template) { create(:item_template, :material, name: "Rat Tail") }
    let!(:inventory_item) { create(:inventory_item, inventory: inventory, item_template: item_template) }

    it "removes the item from inventory" do
      expect {
        delete inventory_item_path(inventory_item)
      }.to change { inventory.inventory_items.count }.by(-1)

      expect(response).to redirect_to(inventory_path)
    end

    it "does not remove equipped items" do
      inventory_item.update!(equipped: true, equipment_slot: "main_hand")

      expect {
        delete inventory_item_path(inventory_item)
      }.not_to change { inventory.inventory_items.count }

      expect(response).to redirect_to(inventory_path)
    end

    it "does not remove protected items" do
      inventory_item.update!(properties: {"protected" => true})

      expect {
        delete inventory_item_path(inventory_item)
      }.not_to change { inventory.inventory_items.count }

      expect(response).to redirect_to(inventory_path)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shop", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:inventory) { character.inventory }
  let(:wallet) { user.currency_wallet }
  let(:city_zone) { create(:zone, name: "Shop Test City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone: city_zone, x: 5, y: 5) }
  let!(:shop_hotspot) { create(:city_hotspot, :shop, zone: city_zone, required_level: 1, active: true) }
  let!(:item_template) do
    create(:item_template,
      key: "shop_spec_knife",
      name: "Shop Spec Knife",
      item_type: "equipment",
      slot: "main_hand",
      base_price: 40,
      weight: 3,
      stack_limit: 10,
      durability_max: 12,
      requirements: {"level" => 1},
      stat_modifiers: {"attack" => 2})
  end

  before do
    wallet.update!(nv_balance: 200)
    sign_in user, scope: :user
  end

  describe "GET /shop" do
    it "renders the Neverlands-style shop frame" do
      get shop_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Лавка")
      expect(response.body).to include("Купить")
      expect(response.body).to include("Shop Spec Knife")
      expect(response.body).to include("Масса")
    end
  end

  describe "POST /shop/buy" do
    it "buys an item into the character inventory" do
      expect {
        post buy_shop_path, params: {item_template_id: item_template.id, quantity: 2}
      }.to change { wallet.reload.nv_balance }.by(-80)
        .and change { inventory.reload.current_weight }.by(6)

      stack = inventory.inventory_items.find_by(item_template:)
      expect(stack.quantity).to eq(2)
      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to include("Куплено")
    end

    it "rejects a purchase when the wallet cannot pay" do
      wallet.update!(nv_balance: 10)

      expect {
        post buy_shop_path, params: {item_template_id: item_template.id, quantity: 1}
      }.not_to change { inventory.inventory_items.count }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to include("Недостаточно NV")
    end
  end

  describe "POST /shop/sell" do
    let!(:inventory_item) do
      create(:inventory_item, inventory:, item_template:, quantity: 2, weight: item_template.weight)
    end

    before do
      inventory.update!(current_weight: 6)
    end

    it "sells one item from a stack and credits the wallet" do
      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, quantity: 1}
      }.to change { wallet.reload.nv_balance }.by(20)
        .and change { inventory.reload.current_weight }.by(-3)

      expect(inventory_item.reload.quantity).to eq(1)
      expect(response).to redirect_to(shop_path(mode: "sell"))
      expect(flash[:notice]).to include("Продано")
    end

    it "rejects equipped items" do
      inventory_item.update!(equipped: true, equipment_slot: "main_hand")

      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, quantity: 1}
      }.not_to change { wallet.reload.nv_balance }

      expect(response).to redirect_to(shop_path(mode: "sell"))
      expect(flash[:alert]).to include("нельзя продать")
    end
  end

  context "outside a city shop" do
    before do
      position.update!(zone: create(:zone, location_type: "outdoor"))
    end

    it "redirects back to the world" do
      get shop_path

      expect(response).to redirect_to(world_path)
      expect(flash[:alert]).to include("городского здания")
    end
  end
end

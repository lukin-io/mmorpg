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
  let!(:shop_account) { ShopAccount.create!(location: shop_hotspot, nv_balance: 1_000) }
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
      stat_modifiers: {"attack" => 2},
      enhancement_rules: {"subcategory" => "knives", "shop" => {"sold" => true}, "shop_stock" => {"current" => 10, "max" => 10}})
  end

  let!(:shop_stock) { ShopStock.create!(shop_account:, item_template:, current: 10, maximum: 20) }

  before do
    wallet.update!(nv_balance: 200)
    sign_in user, scope: :user
  end

  describe "GET /shop" do
    it "renders the Neverlands-style shop frame" do
      get shop_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("game.shop.title"))
      expect(response.body).to include(I18n.t("game.common.buy"))
      expect(response.body).to include("Shop Spec Knife")
      expect(response.body).to include(I18n.t("game.common.mass"))
      expect(response.body).to include(I18n.t("game.shop.shop_funds_html", nv: "0").split("<", 1).first)
      expect(response.body).to include(ApplicationController.helpers.number_with_precision(shop_account.nv_balance, precision: 2))
      row = Nokogiri::HTML(response.body).at_css(".nl-shop-table > tbody > tr")
      expect(row.at_css("span.nl-shop-category__icon.nl-shop-item-icon")).to be_present
      expect(row.at_css("img.nl-shop-item-icon")).to be_nil
    end

    it "reuses the authored item illustration in both buy and sell rows" do
      item_template.update!(key: "penknife")
      create(:inventory_item, inventory:, item_template:)

      %w[buy sell].each do |mode|
        get shop_path(mode:)

        image = Nokogiri::HTML(response.body).at_css(".nl-shop-table img.nl-shop-item-icon")
        expect(image["src"]).to eq(ApplicationController.helpers.image_path("items/penknife.png"))
        expect(image.attributes.slice("width", "height", "alt").transform_values(&:value))
          .to eq("width" => "62", "height" => "91", "alt" => "")
      end
    end

    it "renders an empty assortment without an authored Shop account" do
      ShopStock.where(shop_account:).delete_all
      shop_account.destroy!

      get shop_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("game.shop.empty_section"))
      expect(response.body).not_to include(item_template.name)
      expect(response.body).not_to include(I18n.t("game.shop.shop_funds_html", nv: "0").split("<", 1).first)
      expect(WorldActionOffer.offered.where(character:, action_type: %w[shop_buy shop_sell])).to be_empty
      expect(ShopAccount.where(location: shop_hotspot)).to be_empty
    end

    it "classifies aliased Neverlands equipment slots under the correct shop category" do
      ring = create(:item_template,
        key: "shop_spec_ring",
        name: "Shop Spec Ring",
        item_type: "equipment",
        slot: "ring",
        base_price: 18,
        weight: 1,
        stack_limit: 1,
        durability_max: 30,
        stat_modifiers: {"knowledge" => 3},
        enhancement_rules: {"subcategory" => "jewelry", "shop" => {"sold" => true}, "shop_stock" => {"current" => 10, "max" => 10}})
      ShopStock.create!(shop_account:, item_template: ring, current: 10, maximum: 10)

      get shop_path(category: "jewelry")

      expect(response.body).to include("Shop Spec Ring")
      expect(response.body).not_to include("Shop Spec Knife")
    end

    it "persists the sanitized shop state as the login resume context" do
      get shop_path(
        mode: "sell",
        category: "jewelry",
        min_level: "2",
        max_price: "100",
        return_to: "https://example.invalid"
      )

      expect(character.reload.gameplay_context).to eq(
        "name" => "shop",
        "params" => {
          "mode" => "sell",
          "category" => "jewelry",
          "min_level" => "2",
          "max_price" => "100"
        }
      )
    end

    it "renders persisted license cards with descriptions, hidden ordinary filters, and current stock" do
      license = create(:item_template, key: "trading_license_i", name: "Trading License I", item_type: "misc", slot: "none",
        base_price: 300, weight: 1, durability_max: 1, stack_limit: 1, requirements: {}, stat_modifiers: {},
        enhancement_rules: {"subcategory" => "misc", "description" => "Allows trading with other players.",
                            "shop" => {"sold" => true, "mode" => "licenses", "position" => 1},
                            "license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3, "required_perk" => "merchant"},
                            "shop_stock" => {"current" => 9}})
      ShopStock.create!(shop_account:, item_template: license, current: 9)
      get shop_path
      buy_offer = WorldActionOffer.offered.find_by!(character:, action_type: "shop_buy")

      get shop_path(mode: "licenses", min_level: 100, max_price: 1)

      expect(response).to have_http_status(:success)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css(".nl-shop-tabs [aria-current='page']").text).to eq("Licenses")
      expect(document.css(".nl-shop-categories, .nl-shop-filters")).to be_empty
      expect(document.css("form[action='#{buy_shop_path}'], form[action='#{sell_shop_path}']")).to be_empty
      card = document.at_css(".nl-shop-license")
      expect(card.at_css("img.nl-shop-license__artwork")["src"]).to include("/assets/items/trading_license_i")
      expect(card.text).to include(license.name, "Allows trading with other players.", "300", "3 days", "1/1", "Stock", "9")
      expect(response.body).not_to include(item_template.name)
      expect(buy_offer.reload).to be_cancelled
      expect(WorldActionOffer.offered.where(character:, action_type: %w[shop_buy shop_sell])).to be_empty
      expect(wallet.reload.nv_balance).to eq(200)
      expect(inventory.inventory_items).to be_empty
    end

    it "shows the captured novice denial starting at level ten" do
      character.update!(level: 9)
      get shop_path(mode: "novice")
      expect(response.body).to include(I18n.t("game.shop.novice_empty"))
      expect(Nokogiri::HTML(response.body).css("form[action='#{buy_shop_path}']")).to be_empty

      [10, 11].each do |level|
        character.update!(level:)
        get shop_path(mode: "novice")
        expect(response.body).to include(I18n.t("game.shop.novice_only"))
        expect(Nokogiri::HTML(response.body).css("form[action='#{buy_shop_path}']")).to be_empty
      end
    end

    it "keeps the city Shop return link on the city surface" do
      get shop_path

      document = Nokogiri::HTML(response.body)
      expect(document.css(".nl-shop-controls, .nl-shop-topline")).to be_empty
      expect(document.at_css(".nl-building-entrance__image")["width"]).to eq("1250")
      expect(document.at_css(".nl-top-nav form[data-turbo-frame='main_content'] input[name='context']")["value"]).to eq("inventory")
      expect(document.at_css(".nl-top-nav").at_css("a[href='#{world_path}']").text).to eq("City")
    end

    it "returns a village Shop to the parent interior from shared navigation" do
      outdoors = create(:zone, :mvp_outdoor_region, name: "Shop Village Region")
      position.update!(zone: outdoors, x: 4, y: 6)
      building = create(:tile_building, :world_location, zone: outdoors.name, x: 4, y: 6,
        building_key: "shop_village")

      get shop_path(return_to: "https://example.invalid")

      document = Nokogiri::HTML(response.body)
      parent_path = world_location_path(building.location_key)
      expect(document.at_css(".nl-top-nav a[href='#{parent_path}']").text).to eq("Village")
      expect(document.css(".nl-shop-controls")).to be_empty
      expect(document.css(".nl-top-nav a[href='#{world_path}']")).to be_empty
      expect(character.reload.gameplay_context["name"]).to eq("shop")
      expect(position.reload).to have_attributes(zone: outdoors, x: 4, y: 6)

      get parent_path

      expect(response).to have_http_status(:success)
      expect(character.reload.gameplay_context).to eq("name" => "world_location", "params" => {"key" => building.location_key})
      expect(position.reload).to have_attributes(zone: outdoors, x: 4, y: 6)
    end
  end

  describe "POST /shop/buy" do
    it "rolls back a failed purchase inside the character availability transaction" do
      inventory.update!(slot_capacity: 1, weight_capacity: 100, current_weight: 0)
      item_template.update!(stack_limit: 1)
      create(:inventory_item, inventory:, item_template:)
      action_key = buy_offer

      post buy_shop_path, params: {item_template_id: item_template.id, action_key:}

      expect(response).to redirect_to(shop_path(trade_denied: 1))
      expect(flash[:alert]).to eq(I18n.t("game.inventory.no_free_slots"))
      expect(wallet.reload.nv_balance).to eq(200)
      expect(wallet.currency_transactions).to be_empty
      expect(inventory.reload.current_weight).to eq(0)
      expect(inventory.inventory_items.count).to eq(1)
    end

    it "buys one item into the character inventory" do
      action_key = buy_offer
      expect {
        post buy_shop_path, params: {item_template_id: item_template.id, action_key:}
      }.to change { wallet.reload.nv_balance }.by(-40)
        .and change { inventory.reload.current_weight }.by(3)

      stack = inventory.inventory_items.find_by(item_template:)
      expect(stack.quantity).to eq(1)
      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to include("Bought")
    end

    it "rejects a purchase when the wallet cannot pay" do
      wallet.update!(nv_balance: 10)
      action_key = buy_offer

      expect {
        post buy_shop_path, params: {item_template_id: item_template.id, action_key:}
      }.not_to change { inventory.inventory_items.count }

      expect(response).to redirect_to(shop_path(trade_denied: 1))
      expect(flash[:alert]).to include(I18n.t("game.shop.not_enough_nv"))
    end

    it "surfaces trade_denied recovery chrome when the catalog item is missing" do
      post buy_shop_path, params: {item_template_id: 0}

      expect(response).to redirect_to(shop_path(trade_denied: 1))
      follow_redirect!
      expect(response.body).to include('data-shop-trade-denied="1"')
      expect(response.body).to include('data-shop-recovery="world"')
      expect(response.body).to include('data-shop-recovery="shop"')
      expect(wallet.reload.nv_balance).to eq(200)
    end
  end

  describe "POST /shop/sell" do
    let!(:inventory_item) do
      create(:inventory_item, inventory:, item_template:, quantity: 2, weight: item_template.weight)
    end

    before do
      inventory.update!(current_weight: 6)
      grant_trading_license
    end

    it "sells one item from a stack and credits the wallet" do
      action_key = sell_offer(inventory_item)
      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, action_key:}
      }.to change { wallet.reload.nv_balance }.by(8)
        .and change { inventory.reload.current_weight }.by(-3)
        .and change { shop_stock.reload.current }.by(1)
        .and change { shop_account.reload.nv_balance }.by(-8)

      expect(inventory_item.reload.quantity).to eq(1)
      expect(response).to redirect_to(shop_path(mode: "sell"))
      expect(flash[:notice]).to include("Sold")
    end

    it "prorates resale price by current durability" do
      inventory_item.update!(properties: {"current_durability" => 6, "max_durability" => 12})
      action_key = sell_offer(inventory_item)

      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, action_key:}
      }.to change { wallet.reload.nv_balance }.by(4)
    end

    it "rejects equipped items" do
      action_key = sell_offer(inventory_item)
      inventory_item.update!(equipped: true, equipment_slot: "main_hand")

      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, action_key:}
      }.not_to change { wallet.reload.nv_balance }

      expect(response).to redirect_to(shop_path(mode: "sell", trade_denied: 1))
      expect(flash[:alert]).to include("cannot be sold")
    end

    it "rejects an unequipped item at zero durability" do
      action_key = sell_offer(inventory_item)
      inventory_item.update!(properties: {"current_durability" => 0, "max_durability" => 12})

      expect {
        post sell_shop_path, params: {item_id: inventory_item.id, action_key:}
      }.not_to change { wallet.reload.nv_balance }

      expect(inventory_item.reload.quantity).to eq(2)
      expect(response).to redirect_to(shop_path(mode: "sell", trade_denied: 1))
      expect(flash[:alert]).to include(I18n.t("game.shop.broken_cannot_sell"))
    end
  end

  describe "trade authorization" do
    it "rejects a sale without an active trading license without transferring value" do
      item = create(:inventory_item, inventory:, item_template:)
      action_key = sell_offer(item)

      expect {
        post sell_shop_path, params: {item_id: item.id, action_key:}
      }.not_to change { [wallet.reload.nv_balance, shop_account.reload.nv_balance, shop_stock.reload.current, item.reload.quantity] }

      expect(response).to redirect_to(shop_path(mode: "sell", trade_denied: 1))
      expect(flash[:alert]).to include(I18n.t("game.inventory.trade_license_required"))
    end

    it "rejects missing capabilities without transferring value" do
      get shop_path
      post buy_shop_path, params: {item_template_id: item_template.id}

      expect(response).to redirect_to(shop_path(trade_denied: 1))
      expect(flash[:alert]).to include(I18n.t("game.shop.shop_action_stale"))
      expect(wallet.reload.nv_balance).to eq(200)
      expect(inventory.inventory_items).to be_empty
    end

    it "rejects repeated submissions after a successful purchase" do
      action_key = buy_offer
      2.times { post buy_shop_path, params: {item_template_id: item_template.id, action_key:} }

      expect(wallet.reload.nv_balance).to eq(160)
      expect(inventory.inventory_items.sum(:quantity)).to eq(1)
      expect(wallet.currency_transactions.count).to eq(1)
      expect(response).to redirect_to(shop_path(trade_denied: 1))
      expect(flash[:alert]).to include(I18n.t("game.shop.shop_action_stale"))
    end

    it "rejects client quantity changes instead of silently clamping them" do
      action_key = buy_offer
      [0, 2, 99, -1, "1.5", "invalid"].each do |quantity|
        post buy_shop_path, params: {item_template_id: item_template.id, action_key:, quantity:}
        expect(response).to redirect_to(shop_path(trade_denied: 1))
        expect(flash[:alert]).to include(I18n.t("game.shop.buy_one_at_a_time"))
      end

      expect(wallet.reload.nv_balance).to eq(200)
      expect(inventory.inventory_items).to be_empty
    end

    it "rejects a foreign inventory target even with an owned offer" do
      owned = create(:inventory_item, inventory:, item_template:)
      foreign = create(:inventory_item, item_template:)
      action_key = sell_offer(owned)

      post sell_shop_path, params: {item_id: foreign.id, action_key:}

      expect(response).to redirect_to(shop_path(mode: "sell", trade_denied: 1))
      expect(flash[:alert]).to eq(I18n.t("game.inventory.item_not_found"))
      expect(foreign.reload).to be_persisted
      expect(wallet.reload.nv_balance).to eq(200)
    end

    it "does not accept a trade after logout" do
      action_key = buy_offer
      sign_out user

      post buy_shop_path, params: {item_template_id: item_template.id, action_key:}

      expect(response).to redirect_to(new_user_session_path)
      expect(wallet.reload.nv_balance).to eq(200)
      expect(inventory.inventory_items).to be_empty
    end
  end

  context "outside a city shop" do
    before do
      position.update!(zone: create(:zone, location_type: "outdoor"))
    end

    it "redirects back to the world" do
      get shop_path

      expect(response).to redirect_to(world_path)
      expect(flash[:alert]).to include("accessible trading location")
    end

    it "does not persist a shop context" do
      get shop_path

      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    end
  end

  context "without authentication" do
    it "does not read or update the character context" do
      sign_out user

      get shop_path(mode: "sell")

      expect(response).to redirect_to(new_user_session_path)
      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    end
  end

  it "guides sell-mode players without a trading license" do
    get shop_path(mode: "sell")

    expect(response).to have_http_status(:success)
    expect(response.body).to include('data-shop-sell-onboarding="1"')
    expect(response.body).to include(I18n.t("game.shop.sell_onboarding_title"))
    expect(response.body).to include(I18n.t("game.shop.sell_onboarding_licenses"))
  end

  it "hides sell onboarding once a trading license is active" do
    grant_trading_license

    get shop_path(mode: "sell")

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('data-shop-sell-onboarding="1"')
    expect(response.body).to include('data-shop-sell-license-status="active"')
    expect(response.body).to include(I18n.t("game.shop.sell_license_no_polling"))
  end

  it "shows Doctor license onboarding on the licenses tab" do
    get shop_path(mode: "licenses")

    expect(response).to have_http_status(:success)
    expect(response.body).to include('data-shop-doctor-onboarding="1"')
    expect(response.body).to include(I18n.t("game.shop.doctor_onboarding_title"))
  end

  it "shows a sandbox-empty novice note below level ten" do
    character.update!(level: 5)

    get shop_path(mode: "novice")

    expect(response).to have_http_status(:success)
    expect(response.body).to include('data-shop-novice="empty"')
    expect(response.body).to include(I18n.t("game.shop.novice_empty"))
  end

  it "shows an expired trading-license hint on Sell" do
    grant_trading_license(expires_at: 1.hour.ago)

    get shop_path(mode: "sell")

    expect(response).to have_http_status(:success)
    expect(response.body).to include('data-shop-sell-onboarding="1"')
    expect(response.body).to include('data-shop-sell-license-status="expired"')
    expect(response.body).to include(I18n.t("game.shop.sell_onboarding_licenses"))
  end

  def buy_offer
    get shop_path(category: "knives")
    WorldActionOffer.offered.find_by!(character:, action_type: "shop_buy", target: item_template).action_key
  end

  def sell_offer(item)
    get shop_path(mode: "sell", category: "knives")
    WorldActionOffer.offered.find_by!(character:, action_type: "shop_sell", target: item).action_key
  end

  def grant_trading_license(expires_at: 1.day.from_now)
    template = create(:item_template, key: "trading_license_i", name: "Trading License I", item_type: "misc", slot: "none",
      base_price: 300, weight: 1, durability_max: 1, stack_limit: 1, requirements: {}, stat_modifiers: {},
      enhancement_rules: {"license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3}})
    offer = create(:world_action_offer, character:, zone: city_zone, x: 5, y: 5, action_type: "shop_buy", target: template, status: "completed")
    CharacterLicense.create!(character:, item_template: template, world_action_offer: offer, kind: "trading", tier: 1,
      name: template.name, starts_at: 2.days.ago, expires_at:)
  end
end

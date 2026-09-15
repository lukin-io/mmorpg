# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shop inventory seeds", type: :model do
  def load_shop_seeds(catalog_only: false)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SHOP_CATALOG_ONLY").and_return(catalog_only ? "1" : nil)
    allow($stdout).to receive(:puts)
    load Rails.root.join("db/seeds/shop_inventory.rb")
    zone = Zone.find_or_create_by!(name: Game::World::CityCatalog.node("main").fetch("zone_name")) { |row| row.location_type = "city"; row.width = 10; row.height = 10 }
    shop = CityHotspot.find_by(zone:, key: "shop") || create(:city_hotspot, :shop, zone:)
    load Rails.root.join("db/seeds/shop_accounts.rb")
    ShopAccount.find_by!(location: shop)
  end

  it "authors only captured purchase rows and keeps inventory-only goods out of the assortment" do
    load_shop_seeds

    ordinary = Game::Shop::Catalog.buyable_scope.where("COALESCE(enhancement_rules -> 'shop' ->> 'mode', 'buy') = 'buy'")
    expect(ordinary.count).to eq(80)
    counts = ordinary.group("enhancement_rules ->> 'subcategory'").count
    expect(counts).to eq(%w[knives swords axes blunt polearms staves shields armor helmets boots pants belts gloves bracers jewelry]
      .index_with(5).merge("scrolls" => 5))
    expect(Game::Shop::Catalog.buyable_scope.count).to eq(86)
    expect(ItemTemplate.find_by!(key: "penknife")).to have_attributes(
      base_price: 7, weight: 5, durability_max: 10,
      requirements: {"level" => 1, "ap" => 40},
      stat_modifiers: {"damage_min" => 1, "damage_max" => 2, "armor_pierce" => 1, "weapon_family" => "knife"}
    )
    expect(ItemTemplate.find_by!(key: "hunter_knife").durability_max).to eq(20)
    expect(ItemTemplate.find_by!(key: "reset_scroll")).not_to be_available_in_shop
    expect(ItemTemplate.find_by!(key: "reset_scroll").shop_stock).to be_empty
    expect(ItemTemplate.where(key: %w[practice_knife militia_sword padded_jacket minor_healing_elixir license_market_stall])).to be_empty
  end

  it "preserves source-specific properties instead of filling empty categories with generic goods" do
    load_shop_seeds(catalog_only: true)
    expect(ItemTemplate.find_by!(key: "wood_chips")).not_to be_available_in_shop
    expect(ItemTemplate.find_by!(key: "subtlety_ring").durability_max).to eq(20)
    spear = ItemTemplate.find_by!(key: "parrying_spear")
    expect(spear).to be_two_handed
    expect(spear.requirements).to include("dual_wielding" => 17)
    expect(spear.requirements).not_to have_key("two_handed_mastery")
  end

  it "snapshots owned durability before correcting the shared definition and remains idempotent" do
    template = create(:item_template, key: "subtlety_ring", name: "Subtlety Ring", durability_max: 30)
    inherited = create(:inventory_item, item_template: template, properties: {})
    worn = create(:inventory_item, item_template: template, properties: {"durability" => 12, "bound_note" => "retained"})
    explicit = create(:inventory_item, item_template: template, properties: {"max_durability" => 40, "current_durability" => 0})
    stale_wear = InventoryItem.find(worn.id)
    stale_reset = InventoryItem.find(explicit.id)

    load_shop_seeds(catalog_only: true)

    expect(template.reload.durability_max).to eq(20)
    expect(inherited.reload).to have_attributes(current_durability: 30, max_durability: 30)
    expect(worn.reload).to have_attributes(current_durability: 12, max_durability: 30)
    expect(worn.properties).to include("bound_note" => "retained")
    expect(explicit.reload).to have_attributes(current_durability: 0, max_durability: 40)
    original = [inherited, worn, explicit].map(&:attributes)
    load_shop_seeds(catalog_only: true)
    expect([inherited, worn, explicit].map { |item| item.reload.attributes }).to eq(original)

    expect(stale_wear.decrement_durability!).to eq(11)
    expect(stale_wear.reload).to have_attributes(current_durability: 11, max_durability: 30)
    expect(stale_wear.properties).to include("bound_note" => "retained")
    stale_reset.reset_durability!
    expect(stale_reset.reload).to have_attributes(current_durability: 40, max_durability: 40)
  end

  it "authors all six license descriptions with separate finite stock and no invented maximum" do
    account = load_shop_seeds(catalog_only: true)
    licenses = Game::Shop::Catalog.new(character: build(:character), shop_account: account, params: {mode: "licenses"}).items

    expect(licenses.map(&:key)).to eq(%w[trading_license_i trading_license_ii trading_license_iii doctor_license_i doctor_license_ii doctor_license_iii])
    expect(licenses.map(&:base_price)).to eq([300, 800, 2_000, 300, 550, 800])
    expect(licenses.map { |item| item.enhancement_rules.dig("license", "duration_days") }).to eq([3, 10, 30, 5, 10, 15])
    expect(licenses.map { |item| item.enhancement_rules.dig("license", "tier") }).to eq([1, 2, 3, 1, 2, 3])
    expect(licenses.map { |item| item.shop_stock.fetch("current") }).to eq([9, 666, 4, 10, 9, 10])
    licenses.each do |item|
      expect(item).to have_attributes(item_type: "misc", weight: 1, durability_max: 1, stack_limit: 1)
      expect(item.shop_stock).not_to have_key("max")
      expect(item.description).to be_present
    end
    expect(licenses.first.enhancement_rules.dig("license", "required_perk")).to eq("merchant")
    expect(licenses.first.enhancement_rules.dig("license", "required_unlock")).to eq("merchant")
    expect(licenses.last.enhancement_rules.dig("license", "required_perk")).to eq("healer")
    expect(licenses.last.enhancement_rules.dig("license", "required_unlock")).to eq("traumatologist")
    expect(licenses.last.description).to include("Traumatologist")
  end

  it "never resets traded stock or destroys existing owned legacy templates when repeated" do
    legacy = create(:item_template, key: "practice_knife", base_price: 35,
      enhancement_rules: {"subcategory" => "knives", "shop_stock" => {"current" => 464, "max" => 500}})
    owned = create(:inventory_item, item_template: legacy)
    original = owned.attributes
    account = load_shop_seeds
    penknife = ItemTemplate.find_by!(key: "penknife")
    stock = account.shop_stocks.find_by!(item_template: penknife)
    stock.update!(current: 199)
    account.update!(nv_balance: 12.34)

    expect { load_shop_seeds }.not_to change(ItemTemplate, :count)

    expect(stock.reload.current).to eq(199)
    expect(account.reload.nv_balance).to eq(BigDecimal("12.34"))
    expect(owned.reload.attributes).to eq(original)
    expect(legacy.reload).not_to be_available_in_shop
    expect(account.shop_stocks.where(item_template: legacy)).not_to exist
  end

  it "materializes catalog content without granting or recreating player items in catalog-only mode" do
    user = create(:user, email: "first@lukin.io")
    character = create(:character, user:, name: "max_kerby")
    original_inventory = character.inventory&.attributes

    expect { load_shop_seeds(catalog_only: true) }.not_to change(InventoryItem, :count)

    expect(character.reload.inventory&.attributes).to eq(original_inventory)
    expect(ItemTemplate.find_by!(key: "penknife")).to be_available_in_shop
  end

  it "keeps each shop independent and does not invent village funds" do
    account = load_shop_seeds(catalog_only: true)
    other_shop = create(:city_hotspot, :shop)
    other = ShopAccount.create!(location: other_shop, nv_balance: 5)
    template = ItemTemplate.find_by!(key: "penknife")
    other_stock = other.shop_stocks.create!(item_template: template, current: 2, maximum: 500)

    load_shop_seeds(catalog_only: true)

    expect(other.reload.nv_balance).to eq(5)
    expect(other_stock.reload.current).to eq(2)
    expect(account.shop_stocks.find_by!(item_template: template).current).to eq(196)
    expect(ShopAccount.count).to eq(2)
  end

  it "preserves current durability on previously seeded owned items" do
    user = create(:user, email: "first@lukin.io")
    character = create(:character, user:, name: "max_kerby")
    load_shop_seeds
    item = character.inventory.inventory_items.joins(:item_template).find_by!(item_templates: {key: "knowledge_ring"})
    item.update!(properties: item.properties.merge("current_durability" => 12))
    original = item.attributes

    load_shop_seeds

    expect(item.reload.attributes).to eq(original)
    expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "knowledge_ring"}).count).to eq(1)
  end
end

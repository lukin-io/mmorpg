# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::Catalog do
  let(:character) { build(:character) }
  let(:shop_account) { ShopAccount.create!(location: create(:city_hotspot, :shop), nv_balance: 1_000) }

  def goods(category: "knives", stock: 3, **attributes)
    create(:item_template, base_price: 7, requirements: {"level" => 1},
      enhancement_rules: {"subcategory" => category, "shop" => {"sold" => true},
                          "shop_stock" => {"current" => stock, "max" => 500}}, **attributes).tap do |item|
      ShopStock.create!(shop_account:, item_template: item, current: stock, maximum: 500)
    end
  end

  def catalog(**params)
    described_class.new(character:, shop_account:, params:)
  end

  it "uses the 19 observed categories and defaults old or untrusted categories to knives" do
    expect(described_class::CATEGORIES.size).to eq(19)
    expect(catalog.category).to eq("knives")
    expect(catalog(category: "weapons").category).to eq("knives")
    expect(catalog(category: "potions").category).to eq("knives")
    expect(catalog(category: "runes").category).to eq("runes")
    expect(catalog(mode: "unknown").mode).to eq("buy")
  end

  it "accepts only known filter keys from unpermitted controller parameters" do
    params = ActionController::Parameters.new(category: "jewelry", min_price: "5", forged: "ignored")
    result = described_class.new(character:, params:)
    expect(result.params).to eq("category" => "jewelry", "min_price" => "5")
  end

  it "requires explicit authored availability and retains exhausted rows" do
    knife = goods
    exhausted = goods(stock: 0)
    inventory_only = create(:item_template, base_price: 75, enhancement_rules: {"subcategory" => "knives"})
    goods(category: "armor")

    expect(catalog.items).to contain_exactly(knife, exhausted)
    expect(described_class.buyable_template(knife.id)).to eq(knife)
    expect(described_class.buyable_template(inventory_only.id)).to be_nil
    expect(described_class.buyable_template(nil)).to be_nil
  end

  it "shows only the resolved Shop's authored stock and nothing without an account" do
    expected = goods
    elsewhere = goods
    foreign_account = ShopAccount.create!(location: create(:city_hotspot, :shop), nv_balance: 1_000)
    shop_account.shop_stocks.find_by!(item_template: elsewhere).update!(shop_account: foreign_account)

    expect(catalog.items).to eq([expected])
    expect(described_class.new(character:).items).to be_empty
  end

  it "filters price and level in SQL before hydrating item rows" do
    expected = goods(base_price: 19, requirements: {"level" => 3})
    goods(base_price: 20, requirements: {"level" => 6})
    goods(base_price: 100, requirements: {"level" => 3})
    hydrated = []
    callback = ->(_name, _start, _finish, _id, payload) { hydrated << payload[:record_count] if payload[:class_name] == "ItemTemplate" }
    result = ActiveSupport::Notifications.subscribed(callback, "instantiation.active_record") do
      catalog(min_level: "2", max_level: "5", min_price: "10", max_price: "30").items
    end

    expect(result).to eq([expected])
    expect(hydrated.sum).to eq(1)
  end

  it "applies the captured default ranges and treats malformed filters as defaults" do
    knife = goods
    high_level = goods(requirements: {"level" => 34})
    goods(base_price: 1_000_001)
    expect(catalog(min_level: "bad", max_price: "999999999999999").items).to eq([knife])
    expect(catalog(max_level: "34").items).to contain_exactly(knife, high_level)
    expect(catalog.filters).to eq(min_level: 0, max_level: 33, min_price: 0, max_price: 1_000_000)
  end

  it "returns no guessed novice purchase assortment" do
    goods
    expect(catalog(mode: "novice").items).to be_empty
  end

  it "keeps licenses separate from ordinary goods and ignores their hidden category and numeric filters" do
    knife = goods
    doctor = create(:item_template, key: "doctor_license_i", name: "Doctor License I", item_type: "misc", slot: "none",
      base_price: 300, weight: 1, durability_max: 1, stack_limit: 1, requirements: {}, stat_modifiers: {},
      enhancement_rules: {"subcategory" => "misc", "shop" => {"sold" => true, "mode" => "licenses", "position" => 4},
                          "license" => {"kind" => "doctor", "tier" => 1, "duration_days" => 5, "required_perk" => "healer"}, "shop_stock" => {"current" => 11}})
    trading = create(:item_template, key: "trading_license_i", name: "Trading License I", item_type: "misc", slot: "none",
      base_price: 300, weight: 1, durability_max: 1, stack_limit: 1, requirements: {}, stat_modifiers: {},
      enhancement_rules: {"subcategory" => "misc", "shop" => {"sold" => true, "mode" => "licenses", "position" => 1},
                          "license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3, "required_perk" => "merchant"},
                          "shop_stock" => {"current" => 9}})
    ShopStock.create!(shop_account:, item_template: doctor, current: 11)
    ShopStock.create!(shop_account:, item_template: trading, current: 9)

    expect(catalog(mode: "licenses", category: "knives", min_level: 100, max_price: 1).items).to eq([trading, doctor])
    expect(catalog.items).to eq([knife])
    expect(catalog(category: "misc").items).to be_empty
    expect(described_class.buyable_template(trading.id)).to eq(trading)
  end

  it "filters sell rows by category, level, and base price without extra template reads" do
    inventory = create(:inventory)
    selected = create(:inventory_item, inventory:, item_template: goods(category: "jewelry", base_price: 18, requirements: {"level" => 5}))
    create(:inventory_item, inventory:, item_template: goods(category: "knives", base_price: 18))
    create(:inventory_item, inventory:, item_template: goods(category: "jewelry", base_price: 30, requirements: {"level" => 5}))
    rows = inventory.inventory_items.includes(:item_template).to_a

    expect(catalog(mode: "sell", category: "jewelry", min_level: "5", max_price: "20").sell_items(inventory, loaded_items: rows)).to eq([selected])
    expect(catalog.sell_items(inventory, loaded_items: rows)).to be_empty
  end

  it "uses the observed fractional resale calculation without an invented minimum" do
    template = build(:item_template, base_price: 4, durability_max: 30)
    item = build(:inventory_item, item_template: template, properties: {"current_durability" => 15})
    expect(described_class.sale_price(template)).to eq(BigDecimal("0.80"))
    expect(described_class.sale_price_for_item(item)).to eq(BigDecimal("0.40"))
  end
end

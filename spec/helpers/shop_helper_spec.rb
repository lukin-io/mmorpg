# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShopHelper, type: :helper do
  it "maps source categories to the original five-by-four atlas" do
    expect(helper.shop_category_options.size).to eq(19)
    expect(helper.shop_category_icon_style("knives")).to eq("background-position: 0% 0.0%")
    expect(helper.shop_category_icon_style("staves")).to eq("background-position: 0% 33.333333333333336%")
    expect(helper.shop_category_icon_style("misc")).to eq("background-position: 75% 100.0%")
    expect(helper.shop_category_icon_style("forged")).to eq(helper.shop_category_icon_style("misc"))
  end

  it "shows no invented in-stock claim for an inventory-only template" do
    template = build(:item_template, base_price: 100)
    expect(helper.shop_stock_label(template)).to eq("—")
    expect(helper.shop_buy_block_reason(template)).to eq("Unavailable")
  end

  it "renders the current shop's stock rather than the template bootstrap count" do
    template = build_stubbed(:item_template, enhancement_rules: {"shop_stock" => {"current" => 666}})
    stock = ShopStock.new(current: 665)
    helper.instance_variable_set(:@shop_stocks, {template.id => stock})

    expect(helper.shop_stock_label(template)).to eq("665")
    stock.maximum = 700
    expect(helper.shop_stock_label(template)).to eq("665 / 700")
    helper.instance_variable_set(:@shop_stocks, {})
    expect(helper.shop_stock_label(template)).to eq("—")
  end

  it "uses inventory's readable labels for nested item properties" do
    template = build(:item_template, stat_modifiers: {"skill_bonuses" => {"knife_mastery" => 5}, "weapon_family" => "knife"})
    properties = helper.shop_item_properties(template)
    expect(properties).to include(["Knife Skill", "+5"])
    expect(properties.flatten.join).not_to include("skill_bonuses", "weapon_family")
  end

  it "presents source property order, compact price, durability pair and armor pierce percent" do
    template = build(:item_template, base_price: 7, durability_max: 10,
      stat_modifiers: {"damage_min" => 1, "damage_max" => 2, "armor_pierce" => 1})

    expect(helper.shop_item_properties(template)).to eq([
      ["Price", "7 NV"], ["Damage", "1-2"], ["Durability", "10/10"], ["Armor pierce", "+1%"]
    ])
  end

  it "shows owned durability once when the item's preserved maximum differs from its template" do
    template = build(:item_template, base_price: 7, durability_max: 10)
    item = build(:inventory_item, item_template: template,
      properties: {"current_durability" => 7, "max_durability" => 20})

    durability_rows = helper.shop_item_properties(template, item:).select { |label, _| label.include?("Durability") }

    expect(durability_rows).to eq([["Durability", "7/20"]])
  end

  it "groups mass, level, stats, action points and skills without reordering authored stats" do
    character = build(:character, level: 5)
    helper.define_singleton_method(:current_character) { character }
    helper.instance_variable_set(:@inventory, build(:inventory, current_weight: 0))
    allow(character).to receive(:stats).and_return(instance_double(Game::Systems::StatBlock, get: 3))
    allow(character).to receive(:max_action_points).and_return(100)
    allow(character).to receive(:passive_skill_level).with(:knife_mastery).and_return(0)
    template = build(:item_template, weight: 2,
      requirements: {"knife_mastery" => 5, "ap" => 40, "dexterity" => 4, "level" => 1, "strength" => 2})

    expect(helper.shop_item_requirements(template).map(&:first))
      .to eq(["Mass", "Level", "Dexterity", "Strength", "Action Points", "Knife Skill"])
    expect(helper.shop_item_requirements(template)).to include(["Dexterity", 4, false], ["Strength", 2, true])
  end

  it "shows the safe rejection for legacy durability above the corrected template maximum" do
    template = build(:item_template, base_price: 19, durability_max: 20)
    item = build(:inventory_item, item_template: template, properties: {"current_durability" => 30})
    expect(helper.shop_sell_block_reason(item)).to eq("Invalid durability")
  end

  it "uses controller-preloaded permissions for both buy and sell without querying licenses" do
    character = build_stubbed(:character, perks: {"merchant" => true},
      metadata: {"profession_unlocks" => {"merchant" => true}})
    helper.define_singleton_method(:current_character) { character }
    grant = CharacterLicense.new(character:, kind: "trading", starts_at: 1.day.ago, expires_at: 2.days.from_now)
    helper.instance_variable_set(:@shop_license_rules,
      Game::Shop::LicenseRules.new(character:, active_licenses: [grant]))
    license = build(:item_template, stack_limit: 1, base_price: 300,
      enhancement_rules: {"shop" => {"sold" => true, "mode" => "licenses"},
        "license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3, "required_perk" => "merchant"}})
    template = build_stubbed(:item_template, base_price: 7, durability_max: 10)
    item = build(:inventory_item, item_template: template)
    helper.instance_variable_set(:@shop_stocks, {template.id => ShopStock.new(current: 5, maximum: 500)})
    helper.instance_variable_set(:@shop_account, ShopAccount.new(nv_balance: 1_000))
    expect(CharacterLicense).not_to receive(:where)
    expect(CharacterLicense).not_to receive(:active_at)

    3.times do
      expect(helper.shop_buy_block_reason(license)).to include("already have an active trading license")
      expect(helper.shop_sell_block_reason(item)).to be_nil
    end
  end

  it "reads mass and character requirement values once per render across repeated item rows" do
    character = build(:character, level: 10)
    inventory = build(:inventory, current_weight: 0)
    helper.instance_variable_set(:@inventory, inventory)
    helper.define_singleton_method(:current_character) { character }
    stats = instance_double(Game::Systems::StatBlock, get: 3)
    expect(inventory).to receive(:max_weight).once.and_return(115)
    expect(character).to receive(:stats).once.and_return(stats)
    expect(character).to receive(:max_action_points).once.and_return(100)
    expect(character).to receive(:passive_skill_level).with(:dual_wielding).once.and_return(4)
    template = build(:item_template, requirements: {"strength" => 2, "dexterity" => 5, "ap" => 40, "dual_wield_skill" => 10})

    10.times { helper.shop_item_requirements(template) }

    expect(helper.shop_item_requirements(template)).to include(["Dual Wielding", 10, false])
  end

  it "reports insufficient license funds without implying a physical capacity requirement" do
    character = build_stubbed(:character, perks: {"merchant" => true},
      metadata: {"profession_unlocks" => {"merchant" => true}})
    helper.instance_variable_set(:@shop_license_rules,
      Game::Shop::LicenseRules.new(character:, active_licenses: []))
    license = build_stubbed(:item_template, stack_limit: 1, base_price: 300,
      enhancement_rules: {"shop" => {"sold" => true, "mode" => "licenses"},
        "license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3, "required_perk" => "merchant"}})
    wallet = CurrencyWallet.new(nv_balance: 299)
    helper.instance_variable_set(:@wallet, wallet)
    helper.instance_variable_set(:@shop_stocks, {license.id => ShopStock.new(current: 1)})

    expect(helper.shop_buy_block_reason(license)).to eq("Not enough NV.")
    wallet.nv_balance = 300
    expect(helper.shop_buy_block_reason(license)).to be_nil
  end
end

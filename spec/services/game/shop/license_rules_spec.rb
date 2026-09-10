# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::LicenseRules do
  let(:character) { create(:character) }
  let(:rules) { described_class.new(character:) }

  def license_template(kind: "trading", tier: 1)
    build(:item_template, stack_limit: 1, enhancement_rules: {"license" => {
      "kind" => kind, "tier" => tier, "duration_days" => described_class::DURATIONS.fetch(kind)[tier - 1]
    }})
  end

  it "requires the Merchant perk and completed merchant qualification for Trading" do
    template = license_template
    expect(rules.purchase_block_reason(template)).to eq("Merchant perk required.")
    character.update!(perks: {"merchant" => true})
    expect(rules.purchase_block_reason(template)).to eq("Merchant qualification required.")
    character.update!(metadata: {"profession_unlocks" => {"merchant" => true}})
    expect(rules.purchase_block_reason(template)).to be_nil
  end

  it "requires Healer and the separate Traumatologist qualification for higher Doctor tiers" do
    expect(rules.purchase_block_reason(license_template(kind: "doctor"))).to eq("Healer perk required.")
    character.update!(perks: {"healer" => true})
    expect(rules.purchase_block_reason(license_template(kind: "doctor"))).to be_nil
    [2, 3].each do |tier|
      expect(rules.purchase_block_reason(license_template(kind: "doctor", tier:))).to eq("Traumatologist quest required.")
    end
    character.update!(metadata: {"profession_unlocks" => {"traumatologist" => true}})
    expect(rules.purchase_block_reason(license_template(kind: "doctor", tier: 2))).to be_nil
  end

  it "does not grant permissions from a permanent boolean or an item name" do
    character.inventory.update!(metadata: {"trade_license" => true})
    create(:inventory_item, inventory: character.inventory,
      item_template: create(:item_template, name: "Trading license"))
    expect(rules.active?(:trading)).to be(false)
  end

  it "rejects malformed, mismatched or stacked license definitions" do
    template = license_template
    template.enhancement_rules["license"]["duration_days"] = 300
    expect(described_class.definition(template)).to be_nil
    expect(rules.purchase_block_reason(template)).to eq("This license is unavailable.")
    template = license_template
    template.stack_limit = 2
    expect(rules.purchase_block_reason(template)).to eq("This license is unavailable.")
  end

  it "fails closed for unknown kinds, absent periods and coercible noninteger durations" do
    [nil, true, {"tier" => 1}, {"kind" => "unknown", "tier" => 1},
      {"kind" => "unknown", "tier" => 1, "duration_days" => 3},
      *[nil, 0, -3, "3", 3.0].map { |days| {"kind" => "trading", "tier" => 1, "duration_days" => days} }].each do |definition|
      template = build(:item_template, enhancement_rules: {"license" => definition})
      expect(described_class.definition(template)).to be_nil
      expect(rules.purchase_block_reason(template)).to eq("This license is unavailable.")
    end
  end

  it "recognizes only the six described typed tier and duration pairs" do
    described_class::DURATIONS.each do |kind, durations|
      durations.each_with_index do |days, index|
        template = license_template(kind:, tier: index + 1)
        expect(described_class.definition(template)).to include("kind" => kind, "duration_days" => days, "tier" => index + 1)
      end
    end
  end

  it "reads unbounded profession proficiency without accepting malformed values" do
    [nil, "600", -1, true].each do |value|
      character.metadata = {"profession_skills" => {"trading" => value}}
      expect(described_class.trading_skill(character)).to eq(0)
    end
    character.metadata = {"profession_skills" => "corrupt"}
    expect(described_class.trading_skill(character)).to eq(0)
    character.metadata = {"profession_skills" => {"trading" => 600}}
    expect(described_class.trading_skill(character)).to eq(600)
  end
end

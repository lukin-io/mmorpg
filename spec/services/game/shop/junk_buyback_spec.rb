# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::JunkBuyback do
  let(:character) { create(:character) }

  before do
    Game::Professions::Templates.ensure_craft_items!
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: ItemTemplate.find_by!(key: "wood_chips"),
      quantity: 3
    )
  end

  it "buys materials for NV without a trading license" do
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    before = wallet.nv_balance

    result = described_class.new(character:, item_key: "wood_chips", quantity: 2).call

    expect(result.success).to be(true)
    expect(result.paid).to eq(2)
    expect(wallet.reload.nv_balance).to eq(before + 2)
    expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "wood_chips"}).sum(:quantity)).to eq(1)
  end

  it "buys ash herbs for NV" do
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: ItemTemplate.find_by!(key: "ash_herb"),
      quantity: 2
    )
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    before = wallet.nv_balance

    result = described_class.new(character:, item_key: "ash_herb", quantity: 1).call

    expect(result.success).to be(true)
    expect(result.paid).to eq(3)
    expect(wallet.reload.nv_balance).to eq(before + 3)
    template = create(:item_template, :material, key: "set-blood-ring-t5", name: "Blood Ring T5 Junk")
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: template,
      quantity: 1
    )
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    before = wallet.nv_balance

    result = described_class.new(character:, item_key: "set-blood-ring-t5", quantity: 1).call

    expect(result.success).to be(true)
    expect(result.paid).to eq(8)
    expect(wallet.reload.nv_balance).to eq(before + 8)
  end
end

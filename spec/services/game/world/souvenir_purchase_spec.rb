# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::SouvenirPurchase do
  let(:character) { create(:character) }

  before do
    character.user.create_currency_wallet!(nv_balance: 40)
    Game::Professions::Templates.ensure_craft_items!
  end

  it "buys Ashen bait for NV" do
    result = described_class.new(character:, item_key: "ashen_bait").call

    expect(result.success).to be(true)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(32)
    expect(
      character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "ashen_bait"}).sum(:quantity)
    ).to be >= 1
  end

  it "buys a mite tail for NV" do
    result = described_class.new(character:, item_key: "rat_tail").call

    expect(result.success).to be(true)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(35)
    expect(
      character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "rat_tail"}).sum(:quantity)
    ).to be >= 1
  end

  it "rejects unknown offerings" do
    expect(described_class.new(character:, item_key: "nope").call.success).to be(false)
  end
end

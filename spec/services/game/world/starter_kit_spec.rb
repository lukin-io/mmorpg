# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::StarterKit do
  it "grants bait and starter NV once per character" do
    create(
      :item_template,
      :material,
      key: Game::World::Bait::ITEM_KEY,
      name: "Приманка Завесы",
      weight: 1,
      stack_limit: 99,
      base_price: 5
    )
    character = create(:character)
    described_class.new(character:).call

    expect(Game::World::Bait.new(character:).quantity).to eq(Game::World::Bait::STARTER_GRANT)
    expect(character.user.currency_wallet.nv_balance).to eq(Game::World::StarterKit::STARTER_NV)
    weapon = character.inventory.inventory_items.joins(:item_template).find_by(item_templates: {key: Game::World::StarterKit::WEAPON_KEY})
    expect(weapon).to be_present
    expect(weapon).to be_equipped
    bandage_qty = character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: Game::World::StarterKit::BANDAGE_KEY}).sum(:quantity)
    expect(bandage_qty).to be >= 1
    herb_qty = character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: Game::World::StarterKit::HERB_KEY}).sum(:quantity)
    expect(herb_qty).to be >= 1
    expect(herb_qty).to be <= Game::World::StarterKit::STARTER_HERB
    Game::World::StarterKit::CRAFT_MATS.each do |key, want|
      qty = character.inventory.inventory_items.joins(:item_template).where(item_templates: {key:}).sum(:quantity)
      expect(qty).to be >= 1
      expect(qty).to be <= want
    end

    expect {
      described_class.new(character:).call
    }.not_to change { Game::World::Bait.new(character: character.reload).quantity }
  end

  it "does not raise when carrying capacity is tight" do
    create(
      :item_template,
      :material,
      key: Game::World::Bait::ITEM_KEY,
      name: "Приманка Завесы",
      weight: 1,
      stack_limit: 99,
      base_price: 5
    )
    character = create(:character, level: 0)
    allow(character).to receive(:carrying_capacity).and_return(8)

    expect { described_class.new(character:).call }.not_to raise_error
    expect(character.inventory.inventory_items.joins(:item_template).find_by(item_templates: {key: Game::World::StarterKit::WEAPON_KEY})).to be_present
  end
end

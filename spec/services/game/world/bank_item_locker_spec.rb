# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::BankItemLocker do
  let(:character) { create(:character) }
  let!(:inventory) { character.create_inventory!(slot_capacity: 30, weight_capacity: 100) }

  before do
    Game::Professions::Templates.ensure_craft_items!
    template = ItemTemplate.find_by!(key: "ashen_bait")
    Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: 2)
  end

  it "stores and retrieves one unequipped stack" do
    deposit = described_class.new(character:, action: "deposit", item_key: "ashen_bait", quantity: 1).call
    expect(deposit.success).to be(true)
    expect(described_class.stored_for(character.reload)).to include("item_key" => "ashen_bait", "quantity" => 1)

    withdraw = described_class.new(character:, action: "withdraw").call
    expect(withdraw.success).to be(true)
    expect(described_class.stored_for(character.reload)).to be_nil
  end

  it "rejects a second deposit while occupied" do
    described_class.new(character:, action: "deposit", item_key: "ashen_bait", quantity: 1).call
    second = described_class.new(character:, action: "deposit", item_key: "ashen_bait", quantity: 1).call
    expect(second.success).to be(false)
  end
end

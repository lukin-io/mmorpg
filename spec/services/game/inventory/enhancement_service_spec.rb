require "rails_helper"

RSpec.describe Game::Inventory::EnhancementService do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:item_template) do
    create(:item_template, slot: "main_hand", rarity: "common")
  end
  let(:inventory_item) do
    create(:inventory_item, inventory: character.inventory, item_template: item_template, enhancement_level: 0)
  end
  let(:material_template) { create(:item_template, name: "Weapon Stone", slot: "consumable", rarity: "common") }

  before do
    # Set up gold in wallet
    user.currency_wallet.update!(gold_balance: 10_000)
    # Add required enhancement materials
    create(:inventory_item, inventory: character.inventory, item_template: material_template, quantity: 10)
  end

  it "returns error when max enhancement level reached" do
    inventory_item.update!(enhancement_level: 5) # Max for common

    result = described_class.new(character: character, item: inventory_item).enhance!

    expect(result[:success]).to be false
    expect(result[:error]).to eq("Max enhancement level reached")
  end

  it "enhances item and increments level on success" do
    allow_any_instance_of(described_class).to receive(:rand).and_return(1) # Ensure success

    result = described_class.new(character: character, item: inventory_item).enhance!

    expect(result[:success]).to be true
    expect(result[:level_up]).to be true
    expect(inventory_item.reload.enhancement_level).to eq(1)
  end
end

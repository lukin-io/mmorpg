# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Inventory::EquippedWear do
  it "counts worn and broken equipped durable items" do
    character = create(:character)
    blade = create(:item_template, name: "Wear Blade", slot: "main_hand", durability_max: 10)
    create(
      :inventory_item,
      inventory: character.inventory,
      item_template: blade,
      equipped: true,
      equipment_slot: "main_hand",
      properties: {"current_durability" => 3, "max_durability" => 10}
    )
    shield = create(:item_template, name: "Broken Shield", slot: "off_hand", durability_max: 5)
    create(
      :inventory_item,
      inventory: character.inventory,
      item_template: shield,
      equipped: true,
      equipment_slot: "off_hand",
      properties: {"current_durability" => 0, "max_durability" => 5}
    )

    summary = described_class.summary_for(character)

    expect(summary.worn).to eq(2)
    expect(summary.broken).to eq(1)
  end

  it "returns zeros when nothing is worn" do
    character = create(:character)

    summary = described_class.summary_for(character)

    expect(summary.worn).to eq(0)
    expect(summary.broken).to eq(0)
  end
end

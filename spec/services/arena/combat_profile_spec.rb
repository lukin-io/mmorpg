# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProfile do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:arena_match) { create(:arena_match, status: :live) }
  let(:participation) { create(:arena_participation, arena_match:, character:, user:, team: "a") }

  it "replays the captured Neverlands fight payload from stored metadata" do
    participation.update!(
      metadata: {
        "combat_profile" => {
          "ap_limit" => 140,
          "physical_attack_cost_seed" => 67,
          "max_magic_mana" => 52,
          "block_table" => "normal"
        }
      }
    )

    profile = described_class.for_participation(participation)

    expect(profile).to include(
      "ap_limit" => 140,
      "physical_attack_cost_seed" => 67,
      "simple_attack_cost" => 67,
      "aimed_attack_cost" => 87,
      "max_magic_mana" => 52,
      "block_table" => "normal"
    )
  end

  it "derives physical attack seed from equipped item family when no capture exists" do
    axe = create(:item_template,
      name: "Training Axe",
      slot: "main_hand",
      stat_modifiers: {"attack" => 10, "weapon_family" => "axe"})
    armor = create(:item_template,
      :armor,
      name: "Training Armor",
      stat_modifiers: {"defense" => 10, "weapon_family" => "armor"})
    create(:inventory_item, inventory: character.inventory, item_template: axe, equipped: true)
    create(:inventory_item, inventory: character.inventory, item_template: armor, equipped: true)

    profile = described_class.for_participation(participation)

    expect(profile["physical_attack_cost_seed"]).to eq(58)
    expect(profile["simple_attack_cost"]).to eq(58)
    expect(profile["aimed_attack_cost"]).to eq(78)
  end

  it "switches to shield block table when a shield is equipped" do
    shield = create(:item_template,
      name: "Round Shield",
      slot: "off_hand",
      stat_modifiers: {"defense" => 8, "weapon_family" => "shield"})
    create(:inventory_item, inventory: character.inventory, item_template: shield, equipped: true)

    expect(described_class.for_participation(participation)["block_table"]).to eq("shield")
  end
end

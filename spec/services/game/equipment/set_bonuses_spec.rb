# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Equipment::SetBonuses do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:inventory) { character.inventory || character.create_inventory! }

  def equip_set_piece!(set_id, piece, slot:, tier: 5)
    template = create(
      :item_template,
      key: "set-#{set_id}-#{piece}-t#{tier}",
      name: "set-#{set_id}-#{piece}-t#{tier}",
      item_type: "equipment",
      slot:,
      enhancement_rules: {"set_key" => "set-#{set_id}", "set_name" => set_id, "set_tier" => tier},
      stat_modifiers: {"strength" => 1}
    )
    create(:inventory_item, inventory:, item_template: template, equipped: true, equipment_slot: slot, quantity: 1)
  end

  it "grants ladder bonuses at 2/4 equipped pieces of one set" do
    equip_set_piece!("blood", "weapon", slot: "main_hand")
    equip_set_piece!("blood", "helm", slot: "head")
    result = described_class.new(character:).call
    expect(result.active.first[:set_id]).to eq("blood")
    expect(result.modifiers["attack"]).to eq(2)
    expect(result.modifiers["luck"]).to eq(1)

    equip_set_piece!("blood", "armor", slot: "chest")
    equip_set_piece!("blood", "gloves", slot: "hands")
    result = described_class.new(character: character.reload).call
    expect(result.modifiers["hp"]).to be >= 18
    expect(result.modifiers["attack"]).to be >= 5
  end
end

RSpec.describe Game::World::AshenPopulation do
  it "maps enemy levels into tiers 1..23" do
    expect(described_class.tier_for_level(1)).to eq(1)
    expect(described_class.tier_for_level(50)).to eq(23)
    expect(described_class.tier_for_level(25)).to be_between(10, 14)
  end
end

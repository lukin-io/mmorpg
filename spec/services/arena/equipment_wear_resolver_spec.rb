# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::EquipmentWearResolver do
  let(:rng) { instance_double(Random) }
  let(:match) { create(:arena_match, :completed, metadata: {"source" => "world_npc"}) }
  let(:character) { create(:character) }
  let(:participation) do
    create(:arena_participation, arena_match: match, character:, user: character.user, team: "a", result: :defeat)
  end
  let(:template) { create(:item_template, :durable) }
  let!(:item) do
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: template,
      properties: {"current_durability" => 10})
  end

  it "removes at most one durability point from each successful wilderness-loss roll" do
    participation
    allow(rng).to receive(:rand).with(100).and_return(0)

    result = described_class.new(match:, rng:).call.sole

    expect(result).to have_attributes(character_id: character.id, chance_percent: 50, item_ids: [item.id])
    expect(item.reload.current_durability).to eq(9)
    expect(participation.reload.metadata.dig("equipment_wear", "item_ids")).to eq([item.id])
  end

  it "uses two percent for a wilderness victory and zero for an arena victory" do
    participation.update!(result: :victory)
    allow(rng).to receive(:rand).with(100).and_return(99)

    wilderness = described_class.new(match:, rng:).call.sole
    expect(wilderness.chance_percent).to eq(2)
    expect(item.reload.current_durability).to eq(10)

    match.update!(metadata: {})
    arena = described_class.new(match:, rng:).call.sole
    expect(arena.chance_percent).to eq(0)
    expect(item.reload.current_durability).to eq(10)
  end

  it "skips non-durable and already-broken items" do
    participation
    item.update!(properties: {"current_durability" => 0})
    non_durable = create(:inventory_item, :equipped, inventory: character.inventory)
    expect(rng).not_to receive(:rand)

    result = described_class.new(match:, rng:).call.sole

    expect(result.item_ids).to be_empty
    expect(non_durable.reload).to be_equipped
  end
end

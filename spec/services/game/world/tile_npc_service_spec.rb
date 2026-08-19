# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TileNpcService do
  let(:character) { create(:character) }

  it "returns the persisted NPC placed on the mapped local tile" do
    template = create(
      :npc_template,
      npc_key: "plague_rat",
      name: "Plague Rat",
      level: 4,
      metadata: {
        "health" => 100,
        "base_damage" => 7,
        "avatar_image" => "zombie.png",
        "source_name" => "Plague Rat",
        "source_map" => "m_1001_999",
        "source_coordinates" => [1001, 999]
      }
    )
    create(
      :tile_npc,
      zone: "Outpost Surroundings",
      x: 7,
      y: 7,
      npc_template: template,
      npc_key: template.npc_key,
      level: 4,
      current_hp: 100,
      max_hp: 100
    )
    service = described_class.new(
      character:,
      zone: "Outpost Surroundings",
      x: 7,
      y: 7
    )

    npc = service.tile_npc

    expect(npc.npc_key).to eq("plague_rat")
    expect(npc.display_name).to eq("Plague Rat")
    expect(npc.level).to eq(4)
    expect(npc.current_hp).to eq(100)
    expect(npc.npc_template.metadata).to include(
      "base_damage" => 7,
      "avatar_image" => "zombie.png",
      "source_name" => "Plague Rat",
      "source_map" => "m_1001_999",
      "source_coordinates" => [1001, 999]
    )
  end

  it "does not recreate a deleted placement from seed configuration at runtime" do
    service = described_class.new(
      character:,
      zone: "Outpost Surroundings",
      x: 8,
      y: 7
    )

    expect(service.tile_npc).to be_nil
    expect(service.npc_present?).to be false
  end
end

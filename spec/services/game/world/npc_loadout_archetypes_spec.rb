# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::NpcCombatArchetypes do
  it "maps shore keys to the four Mist-guided archetypes" do
    rat = build_stubbed(:npc_template, npc_key: "plague_rat", metadata: {})
    mite = build_stubbed(:npc_template, npc_key: "ash_gate_mite", metadata: {})
    scout = build_stubbed(:npc_template, npc_key: "ash_shore_scout", metadata: {})
    chanter = build_stubbed(:npc_template, npc_key: "veil_dust_chanter", metadata: {})

    expect(described_class.archetype_for(rat)).to eq("evader")
    expect(described_class.archetype_for(mite)).to eq("tank")
    expect(described_class.archetype_for(scout)).to eq("critter")
    expect(described_class.archetype_for(chanter)).to eq("mage")
  end
end

RSpec.describe Game::World::NpcLoadout do
  it "specializes combat floors by archetype" do
    tank = create(:npc_template, level: 10, npc_key: "ash_gate_mite", metadata: {"world_tier" => 4})
    mage = create(:npc_template, level: 10, npc_key: "veil_dust_chanter", metadata: {"world_tier" => 4})

    tank_stats = described_class.new(npc_template: tank, world_tier: 4, rng: Random.new(1)).call.combat_stats
    mage_stats = described_class.new(npc_template: mage, world_tier: 4, rng: Random.new(1)).call.combat_stats

    expect(tank_stats["combat_archetype"]).to eq("tank")
    expect(mage_stats["combat_archetype"]).to eq("mage")
    expect(tank_stats["hp"]).to be > mage_stats["hp"]
    expect(tank_stats["defense"]).to be > mage_stats["defense"]
    expect(mage_stats["magic_power"]).to be > tank_stats["magic_power"]
  end
end

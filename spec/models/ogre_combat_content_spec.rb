# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Captured Ogre combat content" do
  it "snapshots the three independently observed levels without inventing offense or filling empty slots" do
    definition = Game::World::OutdoorNpcConfig.find_npc("wilderness_ogre")
    npc = create(:npc_template, npc_key: definition.fetch(:key), name: definition.fetch(:name),
      level: definition.fetch(:level), metadata: definition.fetch(:metadata).deep_stringify_keys)
    members = [[16, 1455, 120, 470, 750], [17, 1570, 137, 505, 810], [18, 1685, 151, 535, 870]].map do |level, hp, strength, armor, crushing|
      member = create(:arena_participation, :npc, npc_template: npc,
        metadata: {"level" => level, "current_hp" => hp, "max_hp" => hp})
      member.snapshot_npc_combat_data!
      expect(member.reload.npc_combat_data["display_stats"]).to include(
        "strength" => strength, "armor_class" => armor, "crushing" => crushing, "evasion" => 0
      )
      expect(member.npc_combat_data["equipment"].keys).to contain_exactly(
        "head", "amulet", "main_hand", "feet", "ring_1", "ring_2", "bracers", "hands", "chest", "belt"
      )
      expect(member.npc_combat_data["avatar_image"]).to eq("ogre.png")
      expect(member.max_mp).to eq(7)
      expect(member.max_hp).to eq(hp)
      expect(member.combat_stats[:attack]).to eq(0)
      member
    end
    npc.update!(metadata: {})
    expect(members.map { |member| member.reload.npc_combat_data.dig("display_stats", "armor_class") }).to eq([470, 505, 535])
  end
end

# frozen_string_literal: true

# Soft-release: gate mite must respawn so ash_mite_patrol can collect 3 kills.
class EnableAshenOutdoorGateMiteRespawn < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load path if File.exist?(path)

    TileNpc.where(npc_key: "ash_gate_mite").find_each do |npc|
      meta = npc.metadata.to_h.merge("respawn_seconds" => 45)
      npc.update!(
        max_hp: 45,
        current_hp: 45,
        level: 2,
        defeated_at: nil,
        defeated_by: nil,
        respawns_at: nil,
        metadata: meta
      )
    end

    NpcTemplate.where(npc_key: "ash_gate_mite").find_each do |template|
      meta = template.metadata.to_h.merge(
        "health" => 45,
        "base_damage" => 3,
        "xp_reward" => 18,
        "respawn_seconds" => 45,
        "source_observation" => "ashen_sandbox_gate_mite_soft_release_2026-09-16"
      )
      template.update!(level: 2, metadata: meta)
    end
  end

  def down
  end
end

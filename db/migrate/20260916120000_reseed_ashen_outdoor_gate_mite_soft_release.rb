# frozen_string_literal: true

# Soft-release: reseed gate mite and force live HP so patrol fights are winnable.
# outdoor_npcs seed updates max_hp but keeps existing current_hp; encounters read current_hp first.
class ReseedAshenOutdoorGateMiteSoftRelease < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load path if File.exist?(path)

    TileNpc.where(npc_key: "ash_gate_mite").find_each do |npc|
      npc.update!(max_hp: 45, current_hp: 45, level: 2)
    end

    NpcTemplate.where(npc_key: "ash_gate_mite").find_each do |template|
      meta = template.metadata.to_h.merge(
        "health" => 45,
        "base_damage" => 3,
        "xp_reward" => 18,
        "source_observation" => "ashen_sandbox_gate_mite_soft_release_2026-09-16"
      )
      template.update!(level: 2, metadata: meta)
    end
  end

  def down
  end
end

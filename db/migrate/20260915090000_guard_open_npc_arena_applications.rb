# frozen_string_literal: true

class GuardOpenNpcArenaApplications < ActiveRecord::Migration[8.1]
  def up
    # Preserve duplicate history; only unclaimed NPC offers are retired. Lock
    # writers until the unique index protects the same invariant permanently.
    execute "LOCK TABLE arena_applications IN SHARE ROW EXCLUSIVE MODE"
    execute <<~SQL
      UPDATE arena_applications SET status = 4, updated_at = CURRENT_TIMESTAMP,
        metadata = COALESCE(metadata, '{}'::jsonb) || '{"cancel_reason":"duplicate_npc_offer"}'::jsonb
      WHERE id IN (
        SELECT id FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY arena_room_id, npc_template_id ORDER BY id) AS position
          FROM arena_applications WHERE status = 0 AND npc_template_id IS NOT NULL
        ) duplicates WHERE position > 1
      )
    SQL
    add_index :arena_applications, [:arena_room_id, :npc_template_id], unique: true,
      where: "status = 0 AND npc_template_id IS NOT NULL", name: "one_open_npc_offer_per_room"
  end

  def down
    remove_index :arena_applications, name: "one_open_npc_offer_per_room"
  end
end

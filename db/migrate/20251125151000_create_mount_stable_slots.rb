# frozen_string_literal: true

class CreateMountStableSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :mount_stable_slots do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :slot_index, null: false
      t.string :status, null: false, default: "locked"
      t.references :current_mount, foreign_key: {to_table: :mounts}
      t.jsonb :cosmetics, null: false, default: {}
      t.datetime :unlocked_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :mount_stable_slots, [:user_id, :slot_index], unique: true

    change_table :mounts, bulk: true do |t|
      t.string :faction_key, null: false, default: "neutral"
      t.string :rarity, null: false, default: "common"
      t.references :mount_stable_slot, foreign_key: true
      t.string :summon_state, null: false, default: "stabled"
      t.string :cosmetic_variant, null: false, default: "default"
    end
    add_index :mounts, :faction_key
    add_index :mounts, :rarity
  end
end

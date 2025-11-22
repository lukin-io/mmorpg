# frozen_string_literal: true

class CreateBattleSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :battles do |t|
      t.integer :battle_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.references :zone, foreign_key: true
      t.references :initiator, null: false, foreign_key: {to_table: :characters}
      t.integer :turn_number, null: false, default: 1
      t.jsonb :initiative_order, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.datetime :started_at
      t.datetime :ended_at
      t.boolean :allow_spectators, null: false, default: true
      t.boolean :moderation_override, null: false, default: false
      t.timestamps
    end
    add_index :battles, :status

    create_table :battle_participants do |t|
      t.references :battle, null: false, foreign_key: true
      t.references :character, foreign_key: true
      t.references :npc_template, foreign_key: true
      t.string :role, null: false, default: "combatant"
      t.string :team, null: false, default: "alpha"
      t.integer :initiative, null: false, default: 0
      t.integer :hp_remaining, null: false, default: 0
      t.jsonb :stat_snapshot, null: false, default: {}
      t.jsonb :buffs, null: false, default: {}
      t.timestamps
    end

    create_table :combat_log_entries do |t|
      t.references :battle, null: false, foreign_key: true
      t.integer :round_number, null: false, default: 1
      t.integer :sequence, null: false, default: 1
      t.text :message, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
    add_index :combat_log_entries, [:battle_id, :round_number]

    create_table :arena_rankings do |t|
      t.references :character, null: false, foreign_key: true, index: {unique: true}
      t.integer :rating, null: false, default: 1200
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.integer :streak, null: false, default: 0
      t.jsonb :ladder_metadata, null: false, default: {}
      t.timestamps
    end
  end
end

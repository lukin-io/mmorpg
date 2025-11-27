# frozen_string_literal: true

class CreateDungeonInstances < ActiveRecord::Migration[8.0]
  def change
    create_table :dungeon_instances do |t|
      t.references :dungeon_template, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.references :leader, null: false, foreign_key: {to_table: :characters}

      t.integer :difficulty, default: 1, null: false
      t.integer :status, default: 0, null: false
      t.integer :current_encounter_index, default: 0
      t.integer :attempts_remaining, default: 3
      t.integer :completion_time_seconds

      t.string :instance_key, null: false

      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :dungeon_instances, :instance_key, unique: true
    add_index :dungeon_instances, [:party_id, :status]
  end
end

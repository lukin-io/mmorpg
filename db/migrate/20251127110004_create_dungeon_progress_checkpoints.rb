# frozen_string_literal: true

class CreateDungeonProgressCheckpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :dungeon_progress_checkpoints do |t|
      t.references :dungeon_instance, null: false, foreign_key: true

      t.integer :checkpoint_index, null: false
      t.integer :encounter_index, null: false
      t.jsonb :party_state, default: []

      t.timestamps
    end

    add_index :dungeon_progress_checkpoints, [:dungeon_instance_id, :checkpoint_index],
      unique: true, name: "idx_checkpoints_on_instance_and_index"
  end
end

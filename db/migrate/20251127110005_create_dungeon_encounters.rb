# frozen_string_literal: true

class CreateDungeonEncounters < ActiveRecord::Migration[8.0]
  def change
    create_table :dungeon_encounters do |t|
      t.references :dungeon_instance, null: false, foreign_key: true
      t.integer :encounter_template_id

      t.integer :encounter_index, null: false
      t.integer :status, default: 0, null: false
      t.decimal :difficulty_modifier, precision: 4, scale: 2, default: 1.0

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :dungeon_encounters, [:dungeon_instance_id, :encounter_index],
      unique: true, name: "idx_encounters_on_instance_and_index"
  end
end

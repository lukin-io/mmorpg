# frozen_string_literal: true

class CreateWorldFortresses < ActiveRecord::Migration[8.0]
  def change
    create_table :world_fortresses do |t|
      t.string :zone, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :fortress_key, null: false
      t.string :name, null: false
      t.string :kind, null: false, default: "fortress"
      t.references :owner_character, foreign_key: {to_table: :characters}, null: true
      t.datetime :siege_ends_at
      t.bigint :siege_attacker_id
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :world_fortresses, :fortress_key, unique: true
    add_index :world_fortresses, [:zone, :x, :y], unique: true
  end
end

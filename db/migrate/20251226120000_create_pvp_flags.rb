# frozen_string_literal: true

class CreatePvpFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :pvp_flags do |t|
      t.references :character, null: false, foreign_key: true
      t.integer :flag_type, null: false, default: 0
      t.datetime :expires_at
      t.string :source, limit: 50
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :pvp_flags, [:character_id, :flag_type]
    add_index :pvp_flags, :expires_at

    # Add pvp_enabled to zones for zone-based PVP
    add_column :zones, :pvp_enabled, :boolean, null: false, default: false
    add_column :zones, :pvp_mode, :string, limit: 20, default: nil
  end
end

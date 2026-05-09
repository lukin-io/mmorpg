# frozen_string_literal: true

class CreateWorldActionOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :world_action_offers do |t|
      t.references :character, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.references :target, polymorphic: true
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :action_type, null: false
      t.string :action_key, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :completed_at
      t.string :error_message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :world_action_offers, :action_key, unique: true
    add_index :world_action_offers, [:character_id, :status, :expires_at],
      name: "index_world_action_offers_on_character_status_expires"
    add_index :world_action_offers, [:character_id, :zone_id, :x, :y, :action_type, :status],
      name: "index_world_action_offers_on_character_tile_action_status"
  end
end

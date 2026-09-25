# frozen_string_literal: true

class CreateClansAndFortressBuildings < ActiveRecord::Migration[8.0]
  def change
    create_table :clans do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :tag, null: false
      t.references :leader_character, foreign_key: {to_table: :characters}, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clans, :key, unique: true
    add_index :clans, :tag, unique: true

    create_table :clan_memberships do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true, index: {unique: true}
      t.string :role, null: false, default: "member"
      t.datetime :joined_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clan_memberships, [:clan_id, :character_id], unique: true

    create_table :fortress_buildings do |t|
      t.references :world_fortress, null: false, foreign_key: true
      t.string :building_key, null: false
      t.string :name, null: false
      t.integer :level, null: false, default: 1
      t.jsonb :bonuses, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :fortress_buildings, [:world_fortress_id, :building_key], unique: true

    create_table :fortress_siege_participants do |t|
      t.references :world_fortress, null: false, foreign_key: true
      t.references :clan, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.string :side, null: false # attack | defense
      t.string :wave_key, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :fortress_siege_participants, [:world_fortress_id, :character_id, :wave_key],
      unique: true, name: "index_siege_participants_unique"

    add_reference :world_fortresses, :owner_clan, foreign_key: {to_table: :clans}, null: true
    add_column :world_fortresses, :siege_wave_key, :string
    add_column :world_fortresses, :siege_opens_at, :datetime
    add_column :world_fortresses, :siege_closes_at, :datetime
  end
end

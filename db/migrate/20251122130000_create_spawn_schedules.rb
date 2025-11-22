class CreateSpawnSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :spawn_schedules do |t|
      t.string :region_key, null: false
      t.string :monster_key, null: false
      t.integer :respawn_seconds, null: false, default: 60
      t.string :rarity_override
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}
      t.references :configured_by, null: false, foreign_key: {to_table: :users}
      t.timestamps
    end

    add_index :spawn_schedules, [:region_key, :monster_key], unique: true
  end
end

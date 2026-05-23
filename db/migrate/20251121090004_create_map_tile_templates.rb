class CreateMapTileTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :map_tile_templates do |t|
      t.string :zone, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :terrain_type, null: false
      t.boolean :passable, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :map_tile_templates, [:zone, :x, :y], unique: true
  end
end

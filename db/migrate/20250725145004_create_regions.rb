class CreateRegions < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.string :name
      t.text :description
      t.integer :x_coord
      t.integer :y_coord

      t.timestamps
    end
  end
end

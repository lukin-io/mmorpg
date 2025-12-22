class AddDimensionsToCityHotspots < ActiveRecord::Migration[8.1]
  def change
    add_column :city_hotspots, :width, :integer
    add_column :city_hotspots, :height, :integer
  end
end

class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.string :item_type
      t.string :rarity
      t.jsonb :attrs

      t.timestamps
    end
  end
end

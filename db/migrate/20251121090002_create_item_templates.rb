class CreateItemTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :item_templates do |t|
      t.string :name, null: false
      t.string :slot, null: false
      t.string :rarity, null: false
      t.jsonb :stat_modifiers, null: false, default: {}

      t.timestamps
    end

    add_index :item_templates, :name, unique: true
    add_index :item_templates, :slot
    add_index :item_templates, :rarity
  end
end

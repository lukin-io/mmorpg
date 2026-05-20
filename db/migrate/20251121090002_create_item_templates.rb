class CreateItemTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :item_templates do |t|
      t.string :key
      t.string :name, null: false
      t.string :item_type, default: "equipment"
      t.string :slot, null: false
      t.string :rarity, null: false
      t.jsonb :stat_modifiers, null: false, default: {}
      t.integer :weight, null: false, default: 1
      t.integer :stack_limit, null: false, default: 99
      t.boolean :premium, null: false, default: false
      t.jsonb :enhancement_rules, null: false, default: {}
      t.jsonb :requirements, null: false, default: {}
      t.integer :base_price, null: false, default: 0
      t.integer :durability_max, null: false, default: 0

      t.timestamps
    end

    add_index :item_templates, :key, unique: true
    add_index :item_templates, :name, unique: true
    add_index :item_templates, :item_type
    add_index :item_templates, :slot
    add_index :item_templates, :rarity
  end
end

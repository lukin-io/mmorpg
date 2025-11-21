class CreateCharacterClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :character_classes do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.jsonb :base_stats, null: false, default: {}

      t.timestamps
    end

    add_index :character_classes, :name, unique: true
  end
end

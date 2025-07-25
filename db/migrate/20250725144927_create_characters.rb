class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :class_type
      t.integer :level
      t.integer :xp
      t.integer :hp
      t.integer :mp

      t.timestamps
    end
  end
end

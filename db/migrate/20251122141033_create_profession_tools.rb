class CreateProfessionTools < ActiveRecord::Migration[8.1]
  def change
    create_table :profession_tools do |t|
      t.references :character, null: false, foreign_key: true
      t.references :profession, null: false, foreign_key: true
      t.string :tool_type, null: false
      t.integer :quality_rating, null: false, default: 0
      t.integer :durability, null: false, default: 100
      t.integer :max_durability, null: false, default: 100
      t.boolean :equipped, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :profession_tools, [:character_id, :tool_type]
    add_reference :profession_progresses, :equipped_tool,
      foreign_key: {to_table: :profession_tools}
  end
end

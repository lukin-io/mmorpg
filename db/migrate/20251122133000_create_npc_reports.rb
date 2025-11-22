class CreateNpcReports < ActiveRecord::Migration[8.1]
  def change
    create_table :npc_reports do |t|
      t.references :reporter, null: false, foreign_key: {to_table: :users}
      t.references :character, foreign_key: true
      t.string :npc_key, null: false
      t.integer :category, null: false, default: 0
      t.text :description, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :evidence, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :npc_reports, [:npc_key, :status]
  end
end

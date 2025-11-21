class CreateNpcTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :npc_templates do |t|
      t.string :name, null: false
      t.integer :level, null: false, default: 1
      t.string :role, null: false
      t.text :dialogue, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :npc_templates, :name, unique: true
    add_index :npc_templates, :role
  end
end

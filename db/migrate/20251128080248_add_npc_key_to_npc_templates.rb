# frozen_string_literal: true

class AddNpcKeyToNpcTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :npc_templates, :npc_key, :string
    add_index :npc_templates, :npc_key, unique: true
  end
end

# frozen_string_literal: true

class AddProgressionSourcesToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :progression_sources, :jsonb, null: false, default: {}
  end
end

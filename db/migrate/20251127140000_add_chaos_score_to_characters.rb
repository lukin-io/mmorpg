# frozen_string_literal: true

class AddChaosScoreToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :chaos_score, :integer, default: 0, null: false unless column_exists?(:characters, :chaos_score)
  end
end

# frozen_string_literal: true

class AddPerksToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :perk_points, :integer, null: false, default: 0
    add_column :characters, :perks, :jsonb, null: false, default: {}

    add_index :characters, :perk_points, where: "perk_points > 0"
  end
end

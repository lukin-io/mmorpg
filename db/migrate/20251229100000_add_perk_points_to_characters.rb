# frozen_string_literal: true

class AddPerkPointsToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :perk_points_available, :integer, default: 0, null: false

    # Add index for efficient queries
    add_index :characters, :perk_points_available, where: "perk_points_available > 0"
  end
end

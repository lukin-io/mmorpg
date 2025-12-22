# frozen_string_literal: true

# Adds avatar column to characters for storing player avatar image filename.
# Avatars are randomly assigned on character creation from a predefined set.
class AddAvatarToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :avatar, :string, null: true
  end
end

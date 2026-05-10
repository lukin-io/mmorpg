# frozen_string_literal: true

class AddNeverlandsTravelFieldsToMovementCommands < ActiveRecord::Migration[8.1]
  def change
    add_column :movement_commands, :from_x, :integer
    add_column :movement_commands, :from_y, :integer
    add_column :movement_commands, :target_x, :integer
    add_column :movement_commands, :target_y, :integer
    add_column :movement_commands, :action_key, :string
    add_column :movement_commands, :travel_seconds, :integer
    add_column :movement_commands, :started_at, :datetime
    add_column :movement_commands, :ends_at, :datetime
    add_column :movement_commands, :completed_at, :datetime
    add_column :movement_commands, :failed_at, :datetime

    add_index :movement_commands, :action_key, unique: true
    add_index :movement_commands, [:character_id, :status, :ends_at],
      name: "index_movement_commands_on_character_status_ends"
    add_index :movement_commands, [:character_id, :status, :created_at],
      name: "index_movement_commands_on_character_status_created"
  end
end

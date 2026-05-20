# frozen_string_literal: true

class CreateMovementCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :movement_commands do |t|
      t.references :character, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.string :direction, null: false
      t.integer :status, null: false, default: 0
      t.integer :from_x
      t.integer :from_y
      t.integer :predicted_x
      t.integer :predicted_y
      t.integer :target_x
      t.integer :target_y
      t.string :action_key
      t.integer :travel_seconds
      t.integer :latency_ms, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.datetime :started_at
      t.datetime :ends_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.datetime :processed_at
      t.string :error_message

      t.timestamps
    end

    add_index :movement_commands, :status
    add_index :movement_commands, :created_at
    add_index :movement_commands, :action_key, unique: true
    add_index :movement_commands, [:character_id, :status, :ends_at],
      name: "index_movement_commands_on_character_status_ends"
    add_index :movement_commands, [:character_id, :status, :created_at],
      name: "index_movement_commands_on_character_status_created"
  end
end

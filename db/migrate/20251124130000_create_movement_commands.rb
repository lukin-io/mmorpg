# frozen_string_literal: true

class CreateMovementCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :movement_commands do |t|
      t.references :character, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.string :direction, null: false
      t.integer :status, null: false, default: 0
      t.integer :predicted_x
      t.integer :predicted_y
      t.integer :latency_ms, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.datetime :processed_at
      t.string :error_message

      t.timestamps
    end

    add_index :movement_commands, :status
    add_index :movement_commands, :created_at
  end
end

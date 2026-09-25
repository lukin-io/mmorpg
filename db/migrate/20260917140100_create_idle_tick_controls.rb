# frozen_string_literal: true

# Runtime control plane for idle/activity settle ticks (Ashen Veil controlled tick).
class CreateIdleTickControls < ActiveRecord::Migration[8.1]
  def change
    create_table :idle_tick_controls do |t|
      t.boolean :armed, null: false, default: false
      t.integer :tick_ms, null: false, default: 60_000
      t.integer :batch_size, null: false, default: 25
      t.datetime :last_tick_at
      t.integer :last_ran, null: false, default: 0
      t.integer :last_errors, null: false, default: 0
      t.integer :consecutive_error_ticks, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
  end
end

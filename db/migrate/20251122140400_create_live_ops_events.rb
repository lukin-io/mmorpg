# frozen_string_literal: true

class CreateLiveOpsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :live_ops_events do |t|
      t.references :requested_by, null: false, foreign_key: {to_table: :users}
      t.string :event_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :severity, null: false, default: "normal"
      t.jsonb :payload, null: false, default: {}
      t.text :notes
      t.datetime :executed_at
      t.timestamps
    end

    add_index :live_ops_events, :event_type
    add_index :live_ops_events, :status
    add_index :live_ops_events, :severity
  end
end

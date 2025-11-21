# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :target, polymorphic: true
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end

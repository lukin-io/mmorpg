# frozen_string_literal: true

class CreateManagementAuditEvents < ActiveRecord::Migration[8.1]
  def up
    create_table :management_audit_events do |t|
      t.references :actor, null: false, index: false, foreign_key: {to_table: :users}
      t.string :action, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :record_label, null: false
      t.jsonb :change_set, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :management_audit_events, [:record_type, :record_id]
    add_index :management_audit_events, [:actor_id, :created_at]
    add_index :management_audit_events, :created_at
    add_check_constraint :management_audit_events,
      "action IN ('create', 'update', 'destroy')",
      name: "management_audit_events_action_check"
  end

  def down
    drop_table :management_audit_events
  end
end

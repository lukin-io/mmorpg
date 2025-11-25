# frozen_string_literal: true

class CreateIntegrationTokensAndWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_tokens do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.string :scopes, array: true, default: []
      t.jsonb :metadata, null: false, default: {}
      t.references :created_by, null: false, foreign_key: {to_table: :users}
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :integration_tokens, :token, unique: true

    create_table :webhook_endpoints do |t|
      t.references :integration_token, null: false, foreign_key: true
      t.string :name, null: false
      t.string :target_url, null: false
      t.string :secret, null: false
      t.string :event_types, array: true, default: []
      t.boolean :enabled, null: false, default: true
      t.datetime :last_success_at
      t.datetime :last_error_at
      t.timestamps
    end

    create_table :webhook_events do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :delivery_attempts, null: false, default: 0
      t.datetime :last_attempted_at
      t.timestamps
    end
    add_index :webhook_events, :status
    add_index :webhook_events, :event_type
  end
end

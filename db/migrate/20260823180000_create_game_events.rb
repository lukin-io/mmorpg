# frozen_string_literal: true

class CreateGameEvents < ActiveRecord::Migration[8.1]
  EVENT_TYPES = %w[fight_finished item_found system_information world_announcement].freeze

  def up
    create_table :game_events do |t|
      t.references :recipient, null: true, foreign_key: {to_table: :users}
      t.string :event_type, null: false
      t.string :event_key, null: false
      t.text :body, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :game_events, :event_key, unique: true
    add_index :game_events, [:recipient_id, :occurred_at]
    add_index :game_events, :occurred_at

    add_check_constraint :game_events,
      "event_type IN (#{EVENT_TYPES.map { |type| connection.quote(type) }.join(", ")})",
      name: "game_events_type_check"
    add_check_constraint :game_events,
      "(event_type = 'world_announcement' AND recipient_id IS NULL) OR " \
        "(event_type <> 'world_announcement' AND recipient_id IS NOT NULL)",
      name: "game_events_audience_check"
    add_check_constraint :game_events,
      "jsonb_typeof(payload) = 'object'",
      name: "game_events_payload_object_check"
  end

  def down
    drop_table :game_events
  end
end

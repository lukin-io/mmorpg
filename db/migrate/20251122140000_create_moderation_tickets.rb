# frozen_string_literal: true

class CreateModerationTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_tickets do |t|
      t.references :reporter, null: false, foreign_key: {to_table: :users}
      t.references :subject_user, foreign_key: {to_table: :users}
      t.references :subject_character, foreign_key: {to_table: :characters}
      t.references :assigned_moderator, foreign_key: {to_table: :users}
      t.string :source, null: false
      t.string :category, null: false
      t.string :status, null: false, default: "open"
      t.string :priority, null: false, default: "normal"
      t.string :policy_key
      t.text :policy_summary
      t.string :penalty_state, null: false, default: "none"
      t.datetime :penalty_expires_at
      t.string :appeal_status, null: false, default: "not_requested"
      t.string :origin_reference
      t.string :zone_key
      t.text :description, null: false
      t.jsonb :evidence, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :responded_at
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :moderation_tickets, :status
    add_index :moderation_tickets, :category
    add_index :moderation_tickets, :priority
    add_index :moderation_tickets, :policy_key
    add_index :moderation_tickets, :penalty_state
    add_index :moderation_tickets, :appeal_status
    add_index :moderation_tickets, :zone_key
    add_index :moderation_tickets, :created_at

    add_reference :chat_reports, :moderation_ticket, foreign_key: {to_table: :moderation_tickets}
    add_reference :npc_reports, :moderation_ticket, foreign_key: {to_table: :moderation_tickets}
  end
end

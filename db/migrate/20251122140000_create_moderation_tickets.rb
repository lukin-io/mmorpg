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
    add_index :moderation_tickets, :zone_key
    add_index :moderation_tickets, :created_at
  end
end

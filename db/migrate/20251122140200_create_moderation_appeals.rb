# frozen_string_literal: true

class CreateModerationAppeals < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_appeals do |t|
      t.references :ticket, null: false, foreign_key: {to_table: :moderation_tickets}
      t.references :appellant, null: false, foreign_key: {to_table: :users}
      t.references :reviewer, foreign_key: {to_table: :users}
      t.string :status, null: false, default: "submitted"
      t.text :body, null: false
      t.datetime :sla_due_at
      t.text :resolution_notes
      t.timestamps
    end

    add_index :moderation_appeals, :status
    add_index :moderation_appeals, :sla_due_at
  end
end

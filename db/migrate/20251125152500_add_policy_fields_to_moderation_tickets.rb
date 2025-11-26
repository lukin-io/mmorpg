# frozen_string_literal: true

class AddPolicyFieldsToModerationTickets < ActiveRecord::Migration[8.1]
  def change
    change_table :moderation_tickets, bulk: true do |t|
      t.string :policy_key
      t.text :policy_summary
      t.string :penalty_state, null: false, default: "none"
      t.datetime :penalty_expires_at
      t.string :appeal_status, null: false, default: "not_requested"
    end
    add_index :moderation_tickets, :policy_key
    add_index :moderation_tickets, :penalty_state
    add_index :moderation_tickets, :appeal_status
  end
end

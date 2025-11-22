# frozen_string_literal: true

class AddModerationTicketRefs < ActiveRecord::Migration[8.1]
  def change
    change_table :chat_reports, bulk: true do |t|
      t.references :moderation_ticket, foreign_key: {to_table: :moderation_tickets}
    end

    change_table :npc_reports, bulk: true do |t|
      t.references :moderation_ticket, foreign_key: {to_table: :moderation_tickets}
    end
  end
end

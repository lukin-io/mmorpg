# frozen_string_literal: true

class NpcReport < ApplicationRecord
  enum :category, {
    chat_abuse: 0,
    botting: 1,
    griefing: 2,
    exploit_reports: 3
  }

  enum :status, {
    open: 0,
    investigating: 1,
    resolved: 2,
    dismissed: 3
  }

  belongs_to :reporter, class_name: "User"
  belongs_to :character, optional: true

  validates :npc_key, :description, presence: true
end

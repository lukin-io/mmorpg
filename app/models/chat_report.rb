# frozen_string_literal: true

class ChatReport < ApplicationRecord
  STATUSES = {
    pending: 0,
    reviewing: 1,
    resolved: 2,
    dismissed: 3
  }.freeze

  enum :status, STATUSES

  belongs_to :chat_message, optional: true
  belongs_to :reporter, class_name: "User"

  validates :reason, presence: true
  validates :evidence, presence: true
end

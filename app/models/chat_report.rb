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
  belongs_to :moderation_ticket, class_name: "Moderation::Ticket", optional: true

  validates :reason, presence: true
  validates :evidence, presence: true

  after_create :register_with_chat_message

  def source_summary
    source_context.fetch("source", "chat")
  end

  private

  def register_with_chat_message
    return unless chat_message

    chat_message.register_report!(label: source_summary)
  end
end

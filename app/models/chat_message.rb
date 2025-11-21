# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  include ActionView::RecordIdentifier

  VISIBILITIES = {
    normal: 0,
    system: 1,
    gm_alert: 2
  }.freeze

  enum :visibility, VISIBILITIES

  belongs_to :chat_channel
  belongs_to :sender, class_name: "User"

  validates :body, presence: true
  validates :filtered_body, presence: true

  delegate :channel_type, to: :chat_channel

  before_validation :apply_profanity_filter, if: :will_save_change_to_body?

  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :broadcast_new_message

  private

  def apply_profanity_filter
    filter = Chat::ProfanityFilter.new
    result = filter.call(body)

    self.filtered_body = result.filtered_text
    self.flagged = result.flagged?
  end

  def broadcast_new_message
    broadcast_append_later_to(
      chat_channel,
      target: dom_id(chat_channel, :messages),
      partial: "chat_messages/chat_message",
      locals: {chat_message: self}
    )
  end
end

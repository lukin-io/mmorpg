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

  def register_report!(label: nil)
    labels = moderation_labels
    labels |= [label] if label.present?

    update_columns(
      reported_count: reported_count + 1,
      moderation_labels: labels,
      updated_at: Time.current
    )
  end

  # Check if this is a whisper/private message
  def whisper?
    metadata&.dig("whisper") == true || chat_channel&.channel_type == "whisper"
  end

  # Check if this is a clan message
  def clan_message?
    chat_channel&.channel_type == "clan"
  end

  # Check if this is a party message
  def party_message?
    chat_channel&.channel_type == "party"
  end

  # Check if this is an arena-related message
  def arena_message?
    metadata&.dig("arena") == true
  end

  # Check if the message mentions a specific character
  def mentions?(character)
    return false if character.nil? || body.blank?

    body.downcase.include?("@#{character.name.downcase}")
  end

  private

  def apply_profanity_filter
    filter = Chat::ProfanityFilter.new
    result = filter.call(body)

    self.filtered_body = result.filtered_text
    self.flagged = result.flagged?
  end

  def broadcast_new_message
    # Get all users who should NOT receive this message due to ignore lists
    excluded_ids = Chat::IgnoreFilter.excluded_recipient_ids(sender)

    if excluded_ids.empty?
      # No exclusions - use standard broadcast
      broadcast_append_later_to(
        chat_channel,
        target: dom_id(chat_channel, :messages),
        partial: "chat_messages/chat_message",
        locals: {chat_message: self}
      )
    else
      # Broadcast with ignore filtering via custom job
      BroadcastChatMessageWithIgnoreJob.perform_later(
        id,
        chat_channel.id,
        excluded_ids
      )
    end
  end
end

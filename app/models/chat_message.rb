# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  VISIBILITIES = {
    normal: 0,
    system: 1
  }.freeze

  enum :visibility, VISIBILITIES

  belongs_to :chat_channel
  belongs_to :sender, class_name: "User"

  validates :body, presence: true

  delegate :channel_type, to: :chat_channel

  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :broadcast_new_message

  def whisper?
    metadata&.dig("whisper") == true || chat_channel&.channel_type == "whisper"
  end

  def arena_message?
    metadata&.dig("arena") == true
  end

  def display_body
    body.to_s.gsub(/script/i, "[removed]")
  end

  def addressed_to?(user)
    return false if user.nil? || body.blank?

    names = [user.profile_name, user.character&.name].compact_blank
    names.any? do |name|
      display_body.include?(" #{name}:") || display_body.include?("> #{name}:")
    end
  end

  def timeline_at
    created_at
  end

  private

  def broadcast_new_message
    excluded_ids = Chat::IgnoreFilter.excluded_recipient_ids(sender)
    return if excluded_ids.any?

    Chat::TimelineBroadcaster.chat_message_created(self)
  end
end

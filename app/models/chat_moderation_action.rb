# frozen_string_literal: true

class ChatModerationAction < ApplicationRecord
  ACTION_TYPES = {
    mute_global: 0,
    mute_channel: 1,
    ban_chat: 2
  }.freeze

  enum :action_type, ACTION_TYPES

  belongs_to :target_user, class_name: "User"
  belongs_to :actor, class_name: "User"

  validate :context_is_hash

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :for_user, ->(user) { where(target_user: user) }

  def active?
    expires_at.nil? || expires_at.future?
  end

  def applies_to_channel?(channel)
    return true if ban_chat? || mute_global?
    return false unless mute_channel?

    context_channel_id = context["chat_channel_id"]
    context_channel_id.present? && channel.present? && context_channel_id.to_i == channel.id
  end

  def self.muting?(user:, channel:)
    active.for_user(user).any? { |action| action.applies_to_channel?(channel) }
  end

  private

  def context_is_hash
    errors.add(:context, "must be a JSON object") unless context.is_a?(Hash)
  end
end

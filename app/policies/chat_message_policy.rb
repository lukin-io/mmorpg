# frozen_string_literal: true

class ChatMessagePolicy < ApplicationPolicy
  def create?
    user&.verified_for_social_features? && channel_accessible?
  end

  private

  def channel
    record.respond_to?(:chat_channel) ? record.chat_channel : record
  end

  def channel_accessible?
    return false unless channel

    channel.global? || channel.local? || channel.users.exists?(user.id)
  end
end

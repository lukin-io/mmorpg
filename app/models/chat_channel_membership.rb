# frozen_string_literal: true

class ChatChannelMembership < ApplicationRecord
  enum :role, {
    participant: 0,
    moderator: 1,
    owner: 2
  }

  belongs_to :chat_channel
  belongs_to :user

  validates :chat_channel_id, uniqueness: {scope: :user_id}

  scope :active, -> { all }

  def muted?
    muted_until.present? && muted_until.future?
  end
end

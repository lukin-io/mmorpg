# frozen_string_literal: true

class ChatChannelMembership < ApplicationRecord
  belongs_to :chat_channel
  belongs_to :user

  validates :chat_channel_id, uniqueness: {scope: :user_id}
end

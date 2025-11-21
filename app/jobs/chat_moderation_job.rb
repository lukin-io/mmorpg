# frozen_string_literal: true

class ChatModerationJob < ApplicationJob
  queue_as :chat

  def perform(channel_id)
    Rails.logger.info("Scanning chat channel #{channel_id} for violations")
    # TODO: implement moderation heuristics and penalties.
  end
end

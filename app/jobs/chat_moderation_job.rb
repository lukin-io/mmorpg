# frozen_string_literal: true

# Scans a chat channel for moderation violations and applies penalties.
#
# @example Queue a scan
#   ChatModerationJob.perform_later(channel.id)
#
# @example Scan with custom time window
#   ChatModerationJob.perform_later(channel.id, window_minutes: 30)
#
class ChatModerationJob < ApplicationJob
  queue_as :chat

  # Retry with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(channel_id, window_minutes: 60)
    channel = ChatChannel.find_by(id: channel_id)
    unless channel
      Rails.logger.warn("ChatModerationJob: Channel #{channel_id} not found")
      return
    end

    Rails.logger.info("Scanning chat channel #{channel.name} (#{channel_id}) for violations")

    service = Chat::ModerationService.new
    violations = service.scan_channel(channel, window: window_minutes.minutes)

    # Log summary
    total_violations = violations.values.flatten.size
    users_with_violations = violations.keys.size

    if total_violations.positive?
      Rails.logger.info(
        "ChatModerationJob: Found #{total_violations} violations " \
        "from #{users_with_violations} users in channel #{channel.name}"
      )
    end

    # Broadcast moderation notice if many violations detected
    if total_violations >= 10
      broadcast_moderation_notice(channel)
    end

    {
      channel_id: channel_id,
      violations_found: total_violations,
      users_affected: users_with_violations
    }
  end

  private

  def broadcast_moderation_notice(channel)
    ActionCable.server.broadcast(
      "chat_channel_#{channel.id}",
      {
        type: "system",
        message: "⚠️ Reminder: Please keep chat respectful and follow community guidelines.",
        timestamp: Time.current.iso8601
      }
    )
  end
end

# frozen_string_literal: true

# Broadcasts a chat message to all channel subscribers except those
# who have ignored (or are ignored by) the sender
#
# This job handles the case where ignore lists exist and we need
# to selectively broadcast to specific users instead of the whole channel.
#
# @example Enqueue the job
#   BroadcastChatMessageWithIgnoreJob.perform_later(
#     message_id,
#     channel_id,
#     excluded_user_ids
#   )
#
class BroadcastChatMessageWithIgnoreJob < ApplicationJob
  queue_as :default

  def perform(message_id, channel_id, excluded_user_ids)
    message = ChatMessage.find_by(id: message_id)
    channel = ChatChannel.find_by(id: channel_id)

    return if message.nil? || channel.nil?

    # Get all subscribers to this channel
    subscriber_user_ids = channel.chat_channel_memberships.pluck(:user_id)

    # Filter out excluded users
    recipient_user_ids = subscriber_user_ids - excluded_user_ids

    # Render the message partial once
    html = ApplicationController.render(
      partial: "chat_messages/chat_message",
      locals: {chat_message: message}
    )

    # Broadcast to each non-excluded user individually
    # Using Turbo Streams for each user's personal stream
    recipient_user_ids.each do |user_id|
      Turbo::StreamsChannel.broadcast_append_to(
        [channel, {user_id: user_id}],
        target: ActionView::RecordIdentifier.dom_id(channel, :messages),
        html: html
      )
    end

    # Also broadcast to the general channel stream for new subscribers
    # who may not have ignore entries yet
    Turbo::StreamsChannel.broadcast_append_to(
      channel,
      target: ActionView::RecordIdentifier.dom_id(channel, :messages),
      html: html
    )
  end
end

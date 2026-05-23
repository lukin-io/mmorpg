# frozen_string_literal: true

module ChatMessagesHelper
  def chat_message_classes(message)
    classes = ["chat-msg"]
    classes << "chat-msg--system" if message.system?
    viewer = safe_current_user
    classes << "chat-msg--own" if viewer && message.sender == viewer
    classes << "chat-msg--whisper" if message.whisper?
    classes << "chat-msg--mention" if viewer && message.addressed_to?(viewer)
    classes.join(" ")
  end

  def safe_current_user
    current_user
  rescue Devise::MissingWarden
    nil
  end

  def chat_message_sender_name(message)
    return "System" if message.system?

    sender = message.sender
    return message.metadata&.dig("sender_name") || "Unknown" unless sender

    character = sender.character
    parts = [character&.name || sender.profile_name]
    parts << "[#{character.level}]" if character&.level

    parts.join(" ")
  end

  def chat_message_time(message)
    message.created_at.strftime("%H:%M")
  end
end

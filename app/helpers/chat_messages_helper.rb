# frozen_string_literal: true

module ChatMessagesHelper
  def chat_message_classes(message)
    classes = ["chat-msg"]
    classes << "chat-msg--system" if message.system?
    classes << "chat-msg--gm-alert" if message.gm_alert?
    classes << "chat-msg--flagged" if message.flagged?
    classes << "chat-msg--own" if message.sender == current_user
    classes << "chat-msg--whisper" if message.whisper?
    classes << "chat-msg--clan" if message.clan?
    classes << "chat-msg--party" if message.party?
    classes << "chat-msg--shout" if message.shout?
    classes.join(" ")
  end

  # Format sender name with level and title
  #
  # @param message [ChatMessage] the chat message
  # @return [String] formatted sender name
  def chat_message_sender_name(message)
    return "System" if message.system?

    sender = message.sender
    return message.metadata&.dig("sender_name") || "Unknown" unless sender

    parts = []
    parts << sender.current_title if sender.respond_to?(:current_title) && sender.current_title.present?
    parts << sender.name
    parts << "[#{sender.level}]" if sender.respond_to?(:level)

    parts.join(" ")
  end

  # Convert emoji codes in message content
  #
  # @param content [String] message content
  # @return [String] content with emoji codes converted
  def format_chat_content(content)
    return "" if content.blank?

    # Convert emoji codes
    formatted = ChatEmoji.convert_all(content)

    # Sanitize and make safe
    sanitize(formatted, tags: %w[span], attributes: %w[class title])
  end

  # Format timestamp for chat message
  #
  # @param message [ChatMessage] the message
  # @return [String] formatted time
  def chat_message_time(message)
    message.created_at.strftime("%H:%M")
  end

  # Get emoji picker HTML
  #
  # @return [String] HTML for emoji picker
  def emoji_picker_html
    emojis = ChatEmoji.picker_emojis

    content_tag(:div, class: "emoji-picker") do
      emojis.map do |emoji|
        content_tag(:button,
          emoji.unicode,
          type: "button",
          class: "emoji-btn",
          data: {
            action: "click->chat#insertEmoji",
            emoji: emoji.unicode,
            code: emoji.code
          },
          title: emoji.name
        )
      end.join.html_safe
    end
  end

  # Check if message mentions current user
  #
  # @param message [ChatMessage] the message
  # @return [Boolean] true if current user is mentioned
  def message_mentions_current_user?(message)
    return false unless current_user&.character

    content = message.content.to_s.downcase
    username = current_user.character.name.downcase

    content.include?("@#{username}") || content.include?(username)
  end
end

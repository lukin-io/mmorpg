# frozen_string_literal: true

module ChatMessagesHelper
  def chat_message_classes(message)
    classes = ["chat-msg"]
    classes << "chat-msg--system" if message.system?
    classes << "chat-msg--gm-alert" if message.gm_alert?
    classes << "chat-msg--flagged" if message.flagged?
    classes << "chat-msg--own" if message.sender == current_user
    classes.join(" ")
  end
end

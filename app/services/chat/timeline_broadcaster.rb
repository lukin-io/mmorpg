# frozen_string_literal: true

module Chat
  # Owns the Turbo presentation contract for entries appended to the shared
  # chat timeline. Persistence models only invoke these semantic after-commit
  # hooks; stream names, DOM identity, and partial selection stay here.
  class TimelineBroadcaster
    TARGET_DOM_ID = "chat_timeline"
    GLOBAL_STREAM = "game_events:global"
    PERSONAL_STREAM = "game_events:personal"

    class << self
      def chat_message_created(message)
        message.broadcast_append_later_to(
          message.chat_channel,
          target: TARGET_DOM_ID,
          partial: "chat_messages/chat_message",
          locals: {chat_message: message}
        )
      end

      def game_event_created(event)
        streamables = event.global? ? [GLOBAL_STREAM] : [PERSONAL_STREAM, event.recipient]

        event.broadcast_append_later_to(
          *streamables,
          target: TARGET_DOM_ID,
          partial: "game_events/game_event",
          locals: {game_event: event}
        )
      end
    end
  end
end

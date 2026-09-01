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
        deliver("chat_message", message.id) do
          message.broadcast_append_later_to(
            message.chat_channel,
            target: TARGET_DOM_ID,
            partial: "chat_messages/chat_message",
            locals: {chat_message: message}
          )
        end
      end

      def game_event_created(event)
        streamables = event.global? ? [GLOBAL_STREAM] : [PERSONAL_STREAM, event.recipient]

        deliver("game_event", event.id) do
          event.broadcast_append_later_to(
            *streamables,
            target: TARGET_DOM_ID,
            partial: "game_events/game_event",
            locals: {game_event: event}
          )
        end
      end

      private

      # Timeline delivery is a recoverable presentation side effect. The
      # durable message/event is already committed, so a queue or Redis outage
      # must not turn the authoritative gameplay request into a false failure.
      def deliver(record_type, record_id)
        yield
        true
      rescue StandardError => error
        Rails.logger.warn(
          "[Chat::TimelineBroadcaster] delivery_failed " \
          "record_type=#{record_type.inspect} record_id=#{record_id.inspect} " \
          "error=#{error.class}"
        )
        false
      end
    end
  end
end

# frozen_string_literal: true

module Chat
  # Returns a bounded chronological projection of chat messages and visible
  # gameplay events. Local ordinary rows require the current login/visit; the
  # shared shell also includes world and recipient-owned durable game events.
  class Timeline
    DEFAULT_LIMIT = 200
    MAX_LIMIT = 200

    def initialize(channel:, viewer:, limit: DEFAULT_LIMIT, session: nil, include_game_events: nil)
      @channel = channel
      @viewer = viewer
      @limit = (Integer(limit, exception: false) || DEFAULT_LIMIT).clamp(1, MAX_LIMIT)
      @session = session
      @include_game_events = include_game_events.nil? ? channel.global? : include_game_events
    end

    def call
      if channel.local?
        character = viewer.character
        return [] unless character

        character.with_lock do
          context = LocalContext.new(character:).synchronize!
          session&.reload
          unless session&.user_id == viewer.id && session.signed_out_at.nil? &&
              context && channel.metadata.to_h["location_key"] == context.key
            raise Pundit::NotAuthorizedError, "Chat location or session is no longer available"
          end
          @local_started_at = [context.entered_at, session.signed_in_at].max
          read_entries
        end
      else
        read_entries
      end
    end

    private

    attr_reader :channel, :viewer, :limit, :session, :include_game_events, :local_started_at

    def read_entries
      raise Pundit::NotAuthorizedError unless ChatChannelPolicy.new(viewer, channel).show?

      entries = visible_chat_messages
      entries.concat(visible_game_events) if include_game_events

      entries.sort_by { |entry| [entry.timeline_at, entry.class.name, entry.id] }.last(limit)
    end

    def visible_chat_messages
      return [] if channel.global? || !channel.persisted?

      messages = channel.chat_messages
      messages = messages.where("chat_messages.created_at >= ?", local_started_at) if channel.local?
      messages = messages
        .includes(sender: :characters)
        .order(created_at: :desc, id: :desc)
        .limit(limit)
        .to_a

      Chat::IgnoreFilter.filter_for_user(messages, viewer)
    end

    def visible_game_events
      GameEvent.visible_to(viewer).latest_first.limit(limit).to_a
    end
  end
end

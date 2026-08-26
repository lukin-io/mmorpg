# frozen_string_literal: true

module Chat
  # Returns a bounded chronological projection of chat messages and visible
  # gameplay events. Only the global channel carries the shared event stream.
  class Timeline
    DEFAULT_LIMIT = 200
    MAX_LIMIT = 200

    def initialize(channel:, viewer:, limit: DEFAULT_LIMIT)
      @channel = channel
      @viewer = viewer
      @limit = (Integer(limit, exception: false) || DEFAULT_LIMIT).clamp(1, MAX_LIMIT)
    end

    def call
      entries = visible_chat_messages
      entries.concat(visible_game_events) if channel.global?

      entries.sort_by { |entry| [entry.timeline_at, entry.class.name, entry.id] }.last(limit)
    end

    private

    attr_reader :channel, :viewer, :limit

    def visible_chat_messages
      messages = channel.chat_messages
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

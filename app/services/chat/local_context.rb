# frozen_string_literal: true

module Chat
  # Resolves the current ordinary-chat audience and persists its entry time on
  # the existing character. Position/room transitions call synchronize! inside
  # their transaction; reads repair missing/stale metadata under the same lock.
  # No visit history or browser-provided location is accepted.
  class LocalContext
    METADATA_KEY = "local_chat_context"
    Snapshot = Data.define(:key, :entered_at)

    def initialize(character:, clock: -> { Time.current })
      @character = character
      @clock = clock
    end

    def key
      return unless character&.position&.active?

      Game::World::Presence.new(character:).context_key
    end

    def synchronize!
      return unless character

      character.with_lock do
        character.reload
        current_key = key
        next unless current_key

        saved = character.metadata.to_h[METADATA_KEY]
        entered_at = parse_time(saved)
        if !saved.is_a?(Hash) || saved["key"] != current_key || entered_at.nil?
          entered_at = clock.call
          character.update!(metadata: character.metadata.to_h.merge(
            METADATA_KEY => {"key" => current_key, "entered_at" => entered_at.iso8601(6)}
          ))
        end
        Snapshot.new(key: current_key, entered_at:)
      end
    end

    private

    attr_reader :character, :clock

    def parse_time(saved)
      raw = saved["entered_at"] if saved.is_a?(Hash)
      Time.iso8601(raw) if raw.is_a?(String)
    rescue ArgumentError
      nil
    end
  end
end

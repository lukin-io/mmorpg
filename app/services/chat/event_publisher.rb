# frozen_string_literal: true

module Chat
  # Persists structured, retry-safe gameplay information for the chat timeline.
  #
  # Inputs are server-owned event facts and a stable producer key. The returned
  # GameEvent is created once; repeating the same key with the same identity is
  # idempotent. Turbo delivery happens only after the surrounding transaction
  # commits through GameEvent's model callback.
  class EventPublisher
    class EventKeyConflict < StandardError; end

    def initialize(clock: -> { Time.current })
      @clock = clock
    end

    # Records a completed PvP, PvE, or NPC fight for one participant.
    def fight_finished!(recipient:, experience:, event_key:, payload: {})
      amount = [Integer(experience, exception: false) || 0, 0].max

      publish!(
        recipient:,
        event_type: :fight_finished,
        event_key:,
        body: "Fight finished.",
        payload: payload.merge(experience: amount)
      )
    end

    # Records one successfully awarded item from an authoritative search/loot transition.
    def item_found!(recipient:, item_name:, quantity:, event_key:, payload: {})
      normalized_name = item_name.to_s.strip
      raise ArgumentError, "item name is required" if normalized_name.blank?

      normalized_quantity = [Integer(quantity, exception: false) || 1, 1].max

      publish!(
        recipient:,
        event_type: :item_found,
        event_key:,
        body: "Search result:",
        payload: payload.merge(item_name: normalized_name, quantity: normalized_quantity)
      )
    end

    # Records one successfully deposited NPC-loot currency award.
    def money_found!(recipient:, amount:, currency: "NV", event_key:, payload: {})
      normalized_amount = Integer(amount, exception: false)
      raise ArgumentError, "money amount must be a positive integer" unless normalized_amount&.positive?

      normalized_currency = currency.to_s.upcase
      raise ArgumentError, "unsupported money currency" unless normalized_currency == "NV"

      publish!(
        recipient:,
        event_type: :money_found,
        event_key:,
        body: "Search result:",
        payload: payload.merge(amount: normalized_amount, currency: normalized_currency)
      )
    end

    # Records generic personal system information for a future verified producer.
    def system_information!(recipient:, body:, event_key:, payload: {})
      publish!(recipient:, event_type: :system_information, event_key:, body:, payload:)
    end

    # Records a game-wide announcement. No browser/admin endpoint is exposed.
    def world_announcement!(body:, event_key:, payload: {})
      publish!(event_type: :world_announcement, event_key:, body:, payload:)
    end

    # Persists one allowlisted event type. Callers must supply a stable key that
    # identifies the authoritative source transition.
    def publish!(event_type:, event_key:, body:, payload:, recipient: nil)
      attributes = normalized_attributes(
        recipient:,
        event_type:,
        body:,
        payload:
      )

      event = GameEvent.create_or_find_by!(event_key: event_key.to_s) do |record|
        record.assign_attributes(attributes.merge(occurred_at: clock.call))
      end

      ensure_matching_identity!(event, attributes)
      event
    end

    private

    attr_reader :clock

    def normalized_attributes(recipient:, event_type:, body:, payload:)
      raise ArgumentError, "payload must be an object" unless payload.is_a?(Hash)

      {
        recipient:,
        event_type: event_type.to_s,
        body: body.to_s.strip,
        payload: payload.deep_stringify_keys
      }
    end

    def ensure_matching_identity!(event, expected)
      actual = {
        recipient: event.recipient,
        event_type: event.event_type,
        body: event.body,
        payload: event.payload
      }
      return if actual == expected

      raise EventKeyConflict, "game event key already belongs to another event"
    end
  end
end

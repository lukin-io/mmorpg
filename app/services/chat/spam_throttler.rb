# frozen_string_literal: true

module Chat
  # SpamThrottler enforces per-user, per-channel message limits to keep chat readable.
  # Usage:
  #   Chat::SpamThrottler.new(user:, channel:).check!
  # Returns:
  #   true when under the rate limit. Raises Chat::Errors::SpamThrottledError otherwise.
  class SpamThrottler
    WINDOW = 10.seconds

    def initialize(user:, channel:, cache: Rails.cache, window: WINDOW, limit: nil)
      @user = user
      @channel = channel
      @cache = cache
      @window = window
      @limit = limit || user.message_rate_limit
    end

    def check!
      payload = cache.read(cache_key) || default_payload

      if Time.current > payload[:reset_at]
        payload = default_payload
      end

      if payload[:count] >= limit
        raise Chat::Errors::SpamThrottledError, "Slow down — you're sending messages too quickly."
      end

      payload[:count] += 1

      cache.write(cache_key, payload, expires_in: window)
      true
    end

    private

    attr_reader :user, :channel, :cache, :window, :limit

    def cache_key
      [
        "chat",
        "throttle",
        channel.id,
        user.id
      ].join(":")
    end

    def default_payload
      {
        count: 0,
        reset_at: Time.current + window
      }
    end
  end
end

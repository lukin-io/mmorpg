# frozen_string_literal: true

class Rack::Attack
  # Skip Redis cache in test environment to avoid connection issues
  if Rails.env.test?
    cache.store = ActiveSupport::Cache::MemoryStore.new
  else
  redis_cache_url = ENV.fetch("REDIS_CACHE_URL", "redis://localhost:6379/1")
  cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_cache_url, namespace: "rack-attack")
  end

  # Limit brute force attempts on Devise endpoints.
  throttle("logins/ip", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("logins/email", limit: 20, period: 1.hour) do |req|
    next unless req.path == "/users/sign_in" && req.post?

    email = req.params.dig("user", "email")
    email&.downcase
  end

  throttle("password_resets/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{error: "too_many_requests"}.to_json]
    ]
  end
end

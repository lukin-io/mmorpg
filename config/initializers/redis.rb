# frozen_string_literal: true

module RedisConfig
  module_function

  def cache_url
    ENV.fetch("REDIS_CACHE_URL", "redis://localhost:6379/1")
  end

  def sidekiq_url
    ENV.fetch("REDIS_SIDEKIQ_URL", "redis://localhost:6379/2")
  end

  def cable_url
    ENV.fetch("REDIS_CABLE_URL", "redis://localhost:6379/3")
  end
end

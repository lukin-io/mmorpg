# frozen_string_literal: true

require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = {url: RedisConfig.sidekiq_url}
end

Sidekiq.configure_client do |config|
  config.redis = {url: RedisConfig.sidekiq_url}
end

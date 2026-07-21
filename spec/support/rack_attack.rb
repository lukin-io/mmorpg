# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Rack::Attack.cache.store.clear
  end
end

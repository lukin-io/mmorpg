# frozen_string_literal: true

require "active_job/test_helper"

RSpec.configure do |config|
  config.include ActiveJob::TestHelper, type: :system
  config.include Warden::Test::Helpers, type: :system

  config.before(:each, type: :system) do
    driven_by(:rack_test)
    Warden.test_mode!
  end

  config.before(:each, type: :system, js: true) do
    driven_by(:selenium_chrome_headless)
  end

  config.around(:each, type: :system, js: true) do |example|
    perform_enqueued_jobs { example.run }
  end

  config.after(:each, type: :system) do
    Warden.test_reset!
    clear_enqueued_jobs
    clear_performed_jobs
  end
end

source "https://rubygems.org"

ruby "3.4.4"
gem "rails", "~> 8.1.1"

# Core platform
gem "pg"
gem "puma"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "propshaft"
gem "redis"
gem "connection_pool", "~> 2.4" # Pin to 2.x for Rails 8.1.1 compatibility (connection_pool 3.x has breaking changes)
gem "sidekiq", "~> 8.0"
gem "devise"
gem "pundit"
gem "rolify"
gem "rack-attack"
gem "flipper"
gem "flipper-active_record"
gem "jbuilder"
gem "stripe", "~> 18.0"
gem "view_component", "~> 4.1"
gem "csv"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Utility gems
gem "bootsnap", require: false
gem "image_processing"
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "standard", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "vcr"
  gem "webmock"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
end

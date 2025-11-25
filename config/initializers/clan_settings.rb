# frozen_string_literal: true

# Loads clan gameplay configuration (founding requirements, permissions, XP tables)
# so it can be accessed via Rails.configuration.x.clans throughout the app.
Rails.configuration.x.clans = Rails.application.config_for("gameplay/clans").with_indifferent_access

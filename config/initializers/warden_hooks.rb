# frozen_string_literal: true

# Hooks Devise/Warden lifecycle events so we can hydrate or cleanup
# `UserSession` records without touching controllers.
# Purpose:
#   - Track device-level login/logout activity for presence broadcasts,
#     session security history, and idle detection.
# Usage:
#   - Automatically invoked by Warden after authentication and before logout.
#     No manual calls are required in controllers/jobs.
# Returns:
#   - The callbacks return `nil`; side effects include persisted
#     `UserSession` changes and enqueued presence broadcasts.

Warden::Manager.after_set_user except: :fetch do |user, auth, _opts|
  next unless user.is_a?(User)

  Auth::UserSessionManager.login!(user: user, request: auth.request)
end

Warden::Manager.before_logout do |user, auth, _opts|
  next unless user.is_a?(User)

  Auth::UserSessionManager.logout!(user: user, request: auth.request)
end

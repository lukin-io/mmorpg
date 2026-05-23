# frozen_string_literal: true

Warden::Manager.after_set_user except: :fetch do |user, auth, _opts|
  next unless user.is_a?(User)

  Auth::UserSessionManager.login!(user: user, request: auth.request)
end

Warden::Manager.before_logout do |user, auth, _opts|
  next unless user.is_a?(User)

  Auth::UserSessionManager.logout!(user: user, request: auth.request)
end

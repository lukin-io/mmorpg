# frozen_string_literal: true

# A response started before logout can restore its old authenticated cookie.
# Drop that closed login before Devise's already-authenticated shortcut so the
# first explicit password submission can authenticate normally.
class UserSessionsController < Devise::SessionsController
  prepend_before_action :discard_closed_game_session, only: [:new, :create]
  rescue_from ActionController::InvalidAuthenticityToken, with: :restart_expired_sign_in

  private

  def discard_closed_game_session
    return unless user_signed_in? && current_user_session&.signed_out_at

    sign_out(current_user)
  end

  def restart_expired_sign_in(error)
    raise error unless action_name == "create" && request.format.html?

    # A stale cookie can also replace the anonymous session that issued the
    # form's token. Keep CSRF rejection: no credentials are replayed or saved.
    redirect_to new_user_session_path, status: :see_other,
      alert: "Your sign-in form expired. Please enter your details again."
  end
end

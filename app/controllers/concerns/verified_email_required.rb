# frozen_string_literal: true

module VerifiedEmailRequired
  extend ActiveSupport::Concern

  included do
    before_action :ensure_verified_email!
  end

  private

  def ensure_verified_email!
    return if current_user&.verified_for_social_features?

    respond_to do |format|
      format.html do
        redirect_to root_path, alert: "Verify your email to access this feature."
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: "email_not_verified"}, status: :forbidden }
    end
  end
end

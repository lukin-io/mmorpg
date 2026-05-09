# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentCharacterContext
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_device_identifier

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_device_id

  protected

  def after_sign_in_path_for(resource)
    return world_path if playable_account?(resource)

    dashboard_path
  end

  private

  def playable_account?(resource)
    resource.respond_to?(:characters) && resource.characters.exists?
  end

  def ensure_device_identifier
    current_device_id if user_signed_in?
  end

  def current_device_id
    @current_device_id ||= Auth::DeviceIdentifier.resolve(request)
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        safe_fallback_path = respond_to?(:dashboard_path) ? dashboard_path : root_path
        redirect_target = request.referer.presence

        redirect_target = nil if redirect_target == request.url

        redirect_to(redirect_target || safe_fallback_path, alert: "You are not authorized to perform this action.")
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: "forbidden"}, status: :forbidden }
    end
  end
end

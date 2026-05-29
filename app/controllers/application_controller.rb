# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentCharacterContext
  include ArenaEntryGate
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_device_identifier

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_device_id

  protected

  def after_sign_in_path_for(resource)
    resource.ensure_playable_character! if resource.respond_to?(:ensure_playable_character!)
    world_path
  end

  private

  def ensure_device_identifier
    current_device_id if user_signed_in?
  end

  def current_device_id
    @current_device_id ||= Auth::DeviceIdentifier.resolve(request)
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        redirect_target = request.referer.presence

        redirect_target = nil if redirect_target == request.url

        redirect_to(redirect_target || root_path, alert: "You do not have access to this action.")
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: "forbidden"}, status: :forbidden }
    end
  end
end

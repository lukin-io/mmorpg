# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.html do
        redirect_to(request.referer || root_path, alert: "You are not authorized to perform this action.")
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: "forbidden"}, status: :forbidden }
    end
  end
end

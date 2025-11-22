# frozen_string_literal: true

class PublicProfilesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier

  def show
    @user = User.find_by!(profile_name: params[:profile_name])

    if html_request_without_explicit_format?
      render json: public_profile_payload
    else
      respond_to do |format|
        format.json { render json: public_profile_payload }
        format.html
      end
    end
  end

  private

  def public_profile_payload
    Users::PublicProfile.new(user: @user).as_json
  end

  def html_request_without_explicit_format?
    request.format.html? && params[:format].blank?
  end
end

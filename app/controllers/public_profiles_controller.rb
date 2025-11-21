# frozen_string_literal: true

class PublicProfilesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier

  def show
    user = User.find_by!(profile_name: params[:profile_name])
    render json: Users::PublicProfile.new(user: user).as_json
  end
end

# frozen_string_literal: true

class PublicProfilesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier

  def show
    @user = User.find_by!(profile_name: params[:profile_name])

    respond_to do |format|
      format.json { render json: Users::PublicProfile.new(user: @user).as_json }
      format.html
    end
  end
end

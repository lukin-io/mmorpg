# frozen_string_literal: true

class SocialHubsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  skip_before_action :ensure_device_identifier, only: [:index, :show]

  def index
    @social_hubs = SocialHub.includes(:social_hub_events).order(:name)
  end

  def show
    @social_hub = SocialHub.find_by!(slug: params[:id])
    @upcoming_events = @social_hub.social_hub_events.upcoming.limit(10)
  end
end

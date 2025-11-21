# frozen_string_literal: true

class SessionPingsController < ApplicationController
  protect_from_forgery except: :create

  def create
    SessionPresenceJob.perform_later(
      user_id: current_user.id,
      device_id: device_identifier,
      state: ping_params[:state],
      timestamp: Time.current
    )

    head :accepted
  end

  private

  def ping_params
    params.require(:session_ping).permit(:state)
  end

  def device_identifier
    Auth::DeviceIdentifier.resolve(request)
  end
end

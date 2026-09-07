# frozen_string_literal: true

class SessionPingsController < ApplicationController
  def create
    timestamp = Time.current
    session = current_user.user_sessions.find_by(device_id: device_identifier)
    current_user.mark_last_seen!(timestamp:) if session&.mark_seen!(timestamp:)

    head :no_content
  end

  private

  def device_identifier
    Auth::DeviceIdentifier.resolve(request)
  end
end

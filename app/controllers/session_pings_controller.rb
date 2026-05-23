# frozen_string_literal: true

class SessionPingsController < ApplicationController
  protect_from_forgery except: :create

  def create
    timestamp = Time.current
    session = current_user.user_sessions.find_or_initialize_by(device_id: device_identifier)
    session.signed_in_at ||= timestamp
    session.mark_seen!(timestamp: timestamp)
    current_user.update!(last_seen_at: timestamp)

    head :no_content
  end

  private

  def device_identifier
    Auth::DeviceIdentifier.resolve(request)
  end
end

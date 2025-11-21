# frozen_string_literal: true

class PresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from Presence::Publisher::CHANNEL
  end
end

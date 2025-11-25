# frozen_string_literal: true

class ArenaSpectatorChannel < ApplicationCable::Channel
  def subscribed
    @match = ArenaMatch.find_by(id: params[:match_id])
    reject unless current_user && @match

    stream_from @match.broadcast_channel
  end
end

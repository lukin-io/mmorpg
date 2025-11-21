# frozen_string_literal: true

class GameEventsController < ApplicationController
  def index
    @game_events = policy_scope(GameEvent).order(starts_at: :asc)
  end

  def show
    @game_event = authorize GameEvent.find(params[:id])
  end

  def update
    @game_event = authorize GameEvent.find(params[:id])
    lifecycle = Events::LifecycleService.new(@game_event)

    notice =
      if params[:event_action] == "activate"
        lifecycle.activate!
        "Event activated."
      else
        lifecycle.conclude!(result_payload: params[:result_payload] || {})
        "Event concluded."
      end

    redirect_to game_event_path(@game_event), notice: notice
  end
end

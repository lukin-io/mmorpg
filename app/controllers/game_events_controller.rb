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
        Game::Events::Scheduler.new(@game_event).spawn_instance!(**scheduler_params)
        lifecycle.activate!
        "Event activated."
      else
        lifecycle.conclude!(result_payload: params[:result_payload] || {})
        "Event concluded."
      end

    redirect_to game_event_path(@game_event), notice: notice
  end

  private

  def scheduler_params
    params.permit(
      :announcer_npc_key,
      tournament: [:competition_bracket_id, :name, :announcer_npc_key, {metadata: {}}],
      community_objectives: [:title, :resource_key, :goal_amount, {metadata: {}}]
    ).to_h.deep_symbolize_keys
  end
end

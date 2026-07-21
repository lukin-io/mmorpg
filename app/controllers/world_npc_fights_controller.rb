# frozen_string_literal: true

class WorldNpcFightsController < ApplicationController
  before_action :ensure_active_character!

  def create
    authorize_world_action_offer!(params[:action_key])

    tile_npc = TileNpc.find_by(id: params[:tile_npc_id])
    return respond_with_error("NPC not found.") unless tile_npc
    return respond_with_error("NPC is unavailable.") unless tile_npc.alive?
    return respond_with_error("This NPC is not hostile.") unless tile_npc.hostile?

    match = ActiveRecord::Base.transaction do
      action_offer = Game::World::AcceptAction.new(
        character: current_character,
        action_key: params[:action_key],
        action_type: :attack_npc,
        target: tile_npc
      ).call
      started_match = Game::World::StartNpcFight.new(character: current_character, tile_npc:).call
      action_offer.complete!
      started_match
    end

    respond_to do |format|
      format.html { redirect_to arena_match_path(match), notice: "Fight started." }
      format.turbo_stream { redirect_to arena_match_path(match), status: :see_other }
      format.json { render json: {success: true, match_id: match.id, redirect_url: arena_match_path(match)} }
    end
  rescue Game::World::AcceptAction::ActionViolationError => e
    respond_with_error(e.message)
  rescue Game::World::StartNpcFight::FightViolationError => e
    respond_with_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_error(e.record.errors.full_messages.to_sentence.presence || e.message)
  end

  private

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { redirect_to world_path, status: :see_other, alert: message }
      format.json { render json: {success: false, error: message}, status: :unprocessable_entity }
    end
  end
end

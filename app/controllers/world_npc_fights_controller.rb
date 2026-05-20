# frozen_string_literal: true

class WorldNpcFightsController < ApplicationController
  before_action :ensure_active_character!

  def create
    tile_npc = TileNpc.find_by(id: params[:tile_npc_id])
    return respond_with_error("NPC not found") unless tile_npc
    return respond_with_error("This NPC is not available") unless tile_npc.alive?
    return respond_with_error("This NPC is not hostile") unless tile_npc.hostile?

    action_offer = Game::World::AcceptAction.new(
      character: current_character,
      action_key: params[:action_key],
      action_type: :attack_npc,
      target: tile_npc
    ).call

    match = nil
    ActiveRecord::Base.transaction do
      match = create_match!(tile_npc)
      Arena::CombatProcessor.new(match).start_match
      action_offer.complete!
    end

    respond_to do |format|
      format.html { redirect_to arena_match_path(match), notice: "Fight started." }
      format.turbo_stream { redirect_to arena_match_path(match), status: :see_other }
      format.json { render json: {success: true, match_id: match.id, redirect_url: arena_match_path(match)} }
    end
  rescue Game::World::AcceptAction::ActionViolationError => e
    respond_with_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_error(e.record.errors.full_messages.to_sentence.presence || e.message)
  end

  private

  def create_match!(tile_npc)
    npc = tile_npc.npc_template
    zone = Zone.find_by(name: tile_npc.zone) || current_character.position&.zone
    npc_hp = [tile_npc.current_hp.to_i, npc.health.to_i].select(&:positive?).first || 100

    match = ArenaMatch.create!(
      zone:,
      match_type: :duel,
      status: :pending,
      turn_timeout_seconds: ArenaMatch::DEFAULT_TURN_TIMEOUT,
      trauma_percent: 30,
      metadata: {
        "source" => "world_npc",
        "fight_kind" => "free",
        "is_npc_fight" => true,
        "tile_npc_id" => tile_npc.id,
        "npc_template_id" => npc.id,
        "npc_name" => npc.name,
        "npc_role" => npc.role,
        "zone" => tile_npc.zone,
        "x" => tile_npc.x,
        "y" => tile_npc.y
      }
    )

    ArenaParticipation.create!(
      arena_match: match,
      character: current_character,
      user: current_character.user,
      team: "a",
      joined_at: Time.current
    )

    ArenaParticipation.create!(
      arena_match: match,
      npc_template: npc,
      team: "b",
      joined_at: Time.current,
      metadata: {
        "current_hp" => npc_hp,
        "max_hp" => npc_hp,
        "tile_npc_id" => tile_npc.id
      }
    )

    match
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { redirect_to world_path, status: :see_other, alert: message }
      format.json { render json: {success: false, error: message}, status: :unprocessable_entity }
    end
  end
end

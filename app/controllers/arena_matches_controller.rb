# frozen_string_literal: true

class ArenaMatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_arena_match, only: [:show, :action, :switch_opponent, :claim_timeout, :finish, :log, :confirm_duel, :refuse_duel]
  before_action :require_character, only: [:action, :switch_opponent, :claim_timeout, :finish, :confirm_duel, :refuse_duel]

  def show
    authorize @arena_match

    if @arena_match.cancelled? && @arena_match.metadata.to_h["duel_applicant_id"].present?
      redirect_to arena_room_path(@arena_match.arena_room)
      return
    end

    # The delayed job is the normal start path. A due pending match also starts
    # when either participant reconnects, providing a bounded recovery path if
    # the local worker was temporarily unavailable.
    if @arena_match.start_due?
      Arena::CombatProcessor.new(@arena_match).start_match
      @arena_match.reload
    end

    # Auto-end stale or finished matches
    if @arena_match.auto_end_if_needed!
      flash.now[:notice] = "Fight finished."
    end

    @participations = @arena_match.arena_participations.includes(
      :npc_template,
      character: {inventory: {inventory_items: :item_template}}
    ).order(:id)
    @broadcaster = Arena::CombatBroadcaster.new(@arena_match)

    respond_to do |format|
      format.html do
        render :confirmation if @arena_match.awaiting_duel_confirmation?
      end
      format.json { render json: match_payload }
    end
  end

  def confirm_duel
    authorize @arena_match
    result = Arena::ApplicationHandler.new.confirm_duel(match: @arena_match, character: current_character)
    respond_to do |format|
      format.html { redirect_to @arena_match, alert: result.errors&.join(", "), status: :see_other }
      format.json { render json: {success: result.success?, errors: result.errors}, status: result.success? ? :ok : :unprocessable_entity }
    end
  end

  def refuse_duel
    authorize @arena_match
    result = Arena::ApplicationHandler.new.confirm_duel(match: @arena_match, character: current_character, refuse: true)
    respond_to do |format|
      format.html { redirect_to arena_room_path(@arena_match.arena_room), alert: result.errors&.join(", "), status: :see_other }
      format.json { render json: {success: result.success?, errors: result.errors}, status: result.success? ? :ok : :unprocessable_entity }
    end
  end

  # GET /arena_matches/:id/log
  def log
    authorize @arena_match, :show?
    @combat_log = Arena::CombatLogPresenter.rows_for(@arena_match)

    respond_to do |format|
      format.html { render partial: "arena_matches/combat_log", locals: {log: @combat_log} }
      format.json { render json: {log: @combat_log} }
    end
  end

  # POST /arena_matches/:id/action
  # Submit a complete turn or surrender intent.
  def action
    authorize @arena_match

    @arena_match.auto_end_if_needed!

    processor = Arena::CombatProcessor.new(@arena_match)

    # Build params hash for the action
    action_params = {}
    action_params[:target] = find_action_target if params[:target_id].present?
    action_params[:attacks] = turn_action_array(:attacks) if params[:attacks].present?
    action_params[:blocks] = turn_action_array(:blocks) if params[:blocks].present?
    action_params[:skills] = turn_action_array(:skills) if params[:skills].present?
    action_params[:expected_turn_number] = params[:turn_number] if params[:turn_number].present?

    result = processor.process_player_intent(
      current_character,
      params[:action_type],
      **action_params
    )

    respond_to do |format|
      if result.success?
        message = result[:surrendered] ? "Surrender recorded." : "Turn submitted."
        format.html { redirect_to @arena_match, notice: message, status: :see_other }
        format.json { render json: {success: true, data: result.data} }
        format.turbo_stream { redirect_to @arena_match, notice: message, status: :see_other }
      else
        format.html { redirect_to @arena_match, alert: result.error, status: :see_other }
        format.json { render json: {success: false, error: result.error}, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  # POST /arena_matches/:id/switch_opponent
  def switch_opponent
    authorize @arena_match
    @arena_match.auto_end_if_needed!
    result = Arena::CombatProcessor.new(@arena_match).switch_opponent(
      current_character, expected_switches_used: params[:switches_used]
    )
    respond_to do |format|
      format.html { redirect_to @arena_match, alert: result.error, status: :see_other }
      format.json do
        render json: {success: result.success?, error: result.error, data: result.data},
          status: result.success? ? :ok : :unprocessable_entity
      end
    end
  end

  # POST /arena_matches/:id/claim_timeout
  def claim_timeout
    authorize @arena_match

    @arena_match.auto_end_if_needed!

    result = Arena::CombatProcessor.new(@arena_match).claim_timeout(
      current_character,
      mode: params[:mode]
    )

    respond_to do |format|
      if result.success?
        message = result[:mode] == "draw" ? "Timeout draw recorded." : "Timeout victory recorded."
        format.html { redirect_to @arena_match, notice: message, status: :see_other }
        format.json { render json: {success: true, data: result.data} }
      else
        format.html { redirect_to @arena_match, alert: result.error, status: :see_other }
        format.json { render json: {success: false, error: result.error}, status: :unprocessable_entity }
      end
    end
  end

  # POST /arena_matches/:id/finish
  def finish
    authorize @arena_match

    unless @arena_match.completed?
      respond_to do |format|
        format.html { redirect_to @arena_match, alert: "The fight is still active." }
        format.json do
          render json: {error: "The fight is still active."}, status: :unprocessable_content
        end
        format.turbo_stream { head :unprocessable_content }
      end
      return
    end

    participation = @arena_match.arena_participations.find_by(user: current_user)
    participation.with_lock do
      participation.metadata ||= {}
      participation.metadata["finished_at"] ||= Time.current.iso8601
      participation.save!
      Arena::CombatProcessor.new(@arena_match).publish_npc_finish_notice!(participation)
    end
    current_character.with_lock do
      # Replaying an old Finish must never clear a newer fight's state.
      unless current_character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
        current_character.exit_combat! if current_character.in_combat?
      end
    end

    redirect_to finish_destination_path, notice: "Fight finished.", status: :see_other
  end

  private

  def require_character
    unless current_character
      redirect_to arena_index_path, alert: "A character is required to participate."
    end
  end

  def current_character
    @current_character ||= current_user.characters.first
  end
  helper_method :current_character

  def find_action_target
    target_id = params[:target_id]
    return nil unless target_id

    # Check if target is a character
    participation = @arena_match.arena_participations.find_by(character_id: target_id)
    return participation.character if participation&.character

    # Check if target is an NPC (format: "npc-123")
    if target_id.to_s.start_with?("npc-participation-")
      participation_id = target_id.to_s.delete_prefix("npc-participation-").to_i
      return @arena_match.arena_participations.npcs.find_by(id: participation_id)
    end

    if target_id.to_s.start_with?("npc-")
      npc_id = target_id.to_s.sub("npc-", "").to_i
      return @arena_match.arena_participations.find_by(npc_template_id: npc_id)
    end

    nil
  end

  def set_arena_match
    @arena_match = ArenaMatch.find(params[:id])
  end

  def match_payload
    {
      id: @arena_match.id,
      status: @arena_match.status,
      match_type: @arena_match.match_type,
      started_at: @arena_match.started_at&.iso8601,
      ended_at: @arena_match.ended_at&.iso8601,
      duration: @arena_match.duration,
      current_turn_number: @arena_match.current_turn_number,
      current_user_waiting: current_user_waiting?,
      current_user_combat: current_user_combat_payload,
      public_log_path: @arena_match.public_log_path,
      participants: @participations.map do |p|
        {
          character_id: p.npc? ? "npc-participation-#{p.id}" : p.character_id,
          character_name: p.participant_name,
          team: p.team,
          result: p.result,
          is_npc: p.npc?,
          current_hp: p.defeat? ? 0 : p.current_hp,
          max_hp: p.max_hp,
          current_mp: p.current_mp,
          max_mp: p.max_mp,
          is_dead: !p.combat_alive?
        }
      end
    }
  end

  def current_user_combat_payload
    participation = @arena_match.arena_participations.find_by(user: current_user)
    return nil unless participation

    profile = Arena::CombatProfile.for_participation(participation, persist: true)
    {
      current_ap: [participation.metadata&.dig("current_ap") || profile["ap_limit"], profile["ap_limit"]].min,
      max_ap: profile["ap_limit"],
      simple_attack_cost: profile["simple_attack_cost"],
      aimed_attack_cost: profile["aimed_attack_cost"]
    }
  end

  def current_user_waiting?
    participation = @arena_match.arena_participations.find_by(user: current_user)
    return false unless participation&.combat_alive?

    pending_turn = participation&.metadata.to_h["pending_turn"]

    pending_turn.present? &&
      pending_turn["turn_number"].to_i == (@arena_match.current_turn_number || 1).to_i
  end

  def turn_action_array(key)
    Array.wrap(normalize_indexed_turn_params(params[key]))
  end

  # Browser form fields such as attacks[0][body_part] arrive as hashes keyed
  # by numeric indexes, while JSON clients send arrays. Normalize both shapes
  # at the HTTP boundary so the combat processor receives one stable contract.
  def normalize_indexed_turn_params(value)
    value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)

    case value
    when Hash
      if value.keys.all? { |key| key.to_s.match?(/\A\d+\z/) }
        value.sort_by { |key, _item| key.to_i }.map { |_key, item| normalize_indexed_turn_params(item) }
      else
        value.transform_values { |item| normalize_indexed_turn_params(item) }
      end
    when Array
      value.map { |item| normalize_indexed_turn_params(item) }
    else
      value
    end
  end

  def finish_destination_path
    participation = @arena_match.arena_participations.find_by(character: current_character)
    return inventory_path if participation&.metadata.to_h["scroll_entry"]
    if @arena_match.metadata.to_h["source"] == "scroll_pvp"
      return Game::World::ResumeContext.new(character: current_character).resume_path
    end
    if @arena_match.metadata.to_h["physical_only"]
      room = @arena_match.arena_room
      context = Game::World::ResumeContext.new(character: current_character)
      return arena_room_path(room, ft: @arena_match.team_battle? ? 2 : 1) if context.remember_arena_room!(room:)
    end
    return arena_index_path unless @arena_match.metadata.to_h["source"] == "world_npc"

    Game::World::CombatReturnContext.new(character: current_character).path_for(
      @arena_match.metadata.to_h["return_context"]
    )
  end
end

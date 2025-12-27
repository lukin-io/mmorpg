# frozen_string_literal: true

# Handles open-world PVP combat between players.
# Uses the unified combat system with PVP-specific rules.
class PvpCombatController < ApplicationController
  include CurrentCharacterContext

  before_action :authenticate_user!
  before_action :ensure_active_character!
  before_action :set_target, only: [:attack, :create]
  before_action :set_battle, only: [:show, :action, :turn, :flee, :surrender]
  before_action :authorize_battle!, only: [:show, :action, :turn, :flee, :surrender]

  # GET /pvp_combat/:id
  # Show the PVP battle view
  def show
    authorize @battle, policy_class: PvpCombatPolicy
    setup_battle_view_variables
  end

  # POST /pvp_combat/attack
  # Initiate a PVP attack on another player
  def attack
    service = Game::Combat::PvpEncounterService.new(current_character, @target)
    result = service.start_encounter!

    respond_to do |format|
      if result.success
        format.html { redirect_to pvp_combat_path(result.battle), notice: result.message }
        format.turbo_stream do
          @battle = result.battle
          setup_battle_view_variables
          render :attack
        end
        format.json { render json: {battle_id: result.battle.id, message: result.message} }
      else
        format.html { redirect_back fallback_location: world_path, alert: result.message }
        format.turbo_stream do
          flash.now[:alert] = result.message
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
        end
        format.json { render json: {error: result.message}, status: :unprocessable_entity }
      end
    end
  end

  # Alias for attack
  def create
    attack
  end

  # POST /pvp_combat/:id/action
  # Process a combat action (attack, defend, skill)
  def action
    authorize @battle, policy_class: PvpCombatPolicy

    service = build_service
    result = service.process_action!(
      character: current_character,
      action_type: params[:action_type]&.to_sym || :attack,
      body_part: params[:body_part],
      skill_id: params[:skill_id]
    )

    respond_to do |format|
      format.turbo_stream do
        @battle = result.battle&.reload || @battle.reload
        @combat_log = result.combat_log || []
        setup_battle_view_variables
        render :action
      end
      format.json { render json: build_json_response(result) }
    end
  end

  # POST /pvp_combat/:id/turn
  # Process a full turn with multiple actions
  def turn
    authorize @battle, policy_class: PvpCombatPolicy

    service = build_service
    result = service.process_turn!(
      character: current_character,
      attacks: turn_params[:attacks] || [],
      blocks: turn_params[:blocks] || [],
      skills: turn_params[:skills] || []
    )

    respond_to do |format|
      format.turbo_stream do
        @battle = result.battle&.reload || @battle.reload
        @combat_log = result.combat_log || []
        setup_battle_view_variables
        render :turn
      end
      format.json { render json: build_json_response(result) }
    end
  end

  # POST /pvp_combat/:id/flee
  # Attempt to flee from combat
  def flee
    authorize @battle, :flee?, policy_class: PvpCombatPolicy

    service = build_service
    result = service.process_action!(
      character: current_character,
      action_type: :flee
    )

    # Check if fled successfully via metadata
    fled_successfully = result.success && result.metadata&.dig(:fled)

    respond_to do |format|
      if fled_successfully
        format.html { redirect_to world_path, notice: "You escaped from combat!" }
        format.turbo_stream { redirect_to world_path, notice: "You escaped!", status: :see_other }
      else
        format.html { redirect_to pvp_combat_path(@battle), alert: result.message }
        format.turbo_stream do
          @battle = result.battle&.reload || @battle.reload
          @combat_log = result.combat_log || []
          setup_battle_view_variables
          render :action
        end
      end
      format.json { render json: {success: result.success, message: result.message, fled: fled_successfully} }
    end
  end

  # POST /pvp_combat/:id/surrender
  # Surrender the fight (forfeit)
  def surrender
    authorize @battle, :surrender?, policy_class: PvpCombatPolicy

    service = build_service
    result = service.process_action!(
      character: current_character,
      action_type: :surrender
    )

    respond_to do |format|
      format.html { redirect_to world_path, notice: "You surrendered the fight." }
      format.turbo_stream { redirect_to world_path, notice: "You surrendered.", status: :see_other }
      format.json { render json: {message: "Surrendered", battle: @battle.reload.as_json} }
    end
  end

  # GET /pvp_combat/status
  # Check PVP flag status for current character
  def status
    flag_service = Game::Pvp::FlagService.new(current_character)

    render json: {
      pvp_flagged: flag_service.pvp_flagged?,
      flags: flag_service.active_flags.map do |flag|
        {
          type: flag.flag_type,
          expires_at: flag.expires_at&.iso8601,
          time_remaining: flag.time_remaining
        }
      end
    }
  end

  # POST /pvp_combat/toggle_pvp
  # Toggle voluntary PVP flag
  def toggle_pvp
    flag_service = Game::Pvp::FlagService.new(current_character)

    result = if flag_service.pvp_flagged? && flag_service.active_flags.voluntary.exists?
      flag_service.disable_pvp!
    else
      flag_service.enable_pvp!
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: world_path, notice: result.message }
      format.turbo_stream do
        @pvp_enabled = flag_service.pvp_flagged?
        render :toggle_pvp
      end
      format.json { render json: {pvp_enabled: flag_service.pvp_flagged?, message: result.message} }
    end
  end

  private

  def set_target
    @target = Character.find_by(id: params[:target_id])
    return if @target

    respond_to do |format|
      format.html { redirect_back fallback_location: world_path, alert: "Target not found." }
      format.json { render json: {error: "Target not found"}, status: :not_found }
    end
  end

  def set_battle
    @battle = Battle.find_by(id: params[:id])
    return if @battle

    respond_to do |format|
      format.html { redirect_to world_path, alert: "Battle not found." }
      format.json { render json: {error: "Battle not found"}, status: :not_found }
    end
  end

  def authorize_battle!
    return unless @battle
    return if @battle.battle_participants.exists?(character: current_character)

    respond_to do |format|
      format.html { redirect_to world_path, alert: "You are not part of this battle." }
      format.json { render json: {error: "Not authorized"}, status: :forbidden }
    end
  end

  def build_service
    opponent = @battle.battle_participants
      .where.not(character: current_character)
      .first&.character

    Game::Combat::PvpEncounterService.new(
      current_character,
      opponent,
      zone: @battle.zone
    )
  end

  def setup_battle_view_variables
    return unless @battle

    @participants = @battle.battle_participants.includes(:character)
    @player_participant = @participants.find { |p| p.character_id == current_character.id }
    @opponent_participant = @participants.find { |p| p.character_id != current_character.id }
    @combat_log ||= @battle.combat_log_entries.order(round_number: :desc, sequence: :desc).limit(20)

    # Action availability
    @can_act = @battle.active? && @player_participant&.is_alive
    @available_attacks = default_attacks
    @available_blocks = default_blocks
  end

  def default_attacks
    [
      {id: "head", name: "Head", cost: 0},
      {id: "torso", name: "Torso", cost: 0},
      {id: "stomach", name: "Stomach", cost: 50},
      {id: "legs", name: "Legs", cost: 90}
    ]
  end

  def default_blocks
    [
      {id: "head", name: "Head", cost: 35},
      {id: "torso", name: "Torso", cost: 50},
      {id: "stomach", name: "Stomach", cost: 60},
      {id: "legs", name: "Legs", cost: 30}
    ]
  end

  def turn_params
    params.permit(
      attacks: [:body_part, :action_key, :action_type, :target_id],
      blocks: [:body_part, :action_key],
      skills: [:skill_id, :target_id]
    )
  end

  def build_json_response(result)
    {
      success: result.success,
      message: result.message,
      combat_log: result.combat_log,
      battle_status: result.battle&.status,
      rewards: result.rewards
    }
  end
end

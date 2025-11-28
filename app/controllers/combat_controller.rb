# frozen_string_literal: true

# Handles PvE combat encounters from the world map
class CombatController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_battle, only: %i[show action flee skills]

  # GET /combat
  # Show current combat status
  def show
    if @battle
      setup_battle_view_variables
    else
      redirect_to world_path, notice: "You are not in combat."
    end
  end

  # POST /combat/start
  # Start combat with an NPC
  def start
    npc_template = NpcTemplate.find_by(id: params[:npc_template_id])

    if npc_template.nil?
      return respond_with_error("NPC not found")
    end

    unless npc_template.role == "hostile"
      return respond_with_error("This NPC is not hostile")
    end

    service = Game::Combat::PveEncounterService.new(current_character, npc_template)
    result = service.start_encounter!

    respond_to do |format|
      if result.success
        format.html { redirect_to combat_path, notice: result.message }
        format.turbo_stream do
          # Set instance variables for the battle partial
          @battle = result.battle
          setup_battle_view_variables
          render turbo_stream: [
            turbo_stream.replace("main_content", partial: "combat/battle"),
            turbo_stream.append("combat-log", partial: "combat/log_entries", locals: {entries: result.combat_log})
          ]
        end
        format.json { render json: {success: true, battle_id: result.battle.id, message: result.message} }
      else
        # If already in combat, redirect to existing battle instead of showing error
        if result.message == "Already in combat"
          set_battle
          if @battle
            format.html { redirect_to combat_path }
            format.turbo_stream do
              setup_battle_view_variables
              render turbo_stream: turbo_stream.replace("main_content", partial: "combat/battle")
            end
            format.json { render json: {success: true, battle_id: @battle.id, message: "Redirecting to existing combat"} }
            return
          end
        end

        format.html { redirect_to world_path, alert: result.message }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: {alert: result.message}) }
        format.json { render json: {success: false, error: result.message}, status: :unprocessable_entity }
      end
    end
  end

  # POST /combat/action
  # Process a combat action (attack, defend, skill)
  def action
    unless @battle
      return respond_with_error("Not in combat")
    end

    action_type = params[:action_type]&.to_sym
    skill_id = params[:skill_id]

    service = Game::Combat::PveEncounterService.new(current_character, nil)
    result = service.process_action!(action_type: action_type, skill_id: skill_id)

    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.append("combat-log", partial: "combat/log_entries", locals: {entries: result.combat_log})
        ]

        streams << if result.battle&.completed?
          turbo_stream.replace("combat-actions", partial: "combat/result", locals: {result: result})
        else
          turbo_stream.replace("combat-status", partial: "combat/status", locals: {battle: result.battle})
        end

        render turbo_stream: streams
      end
      format.json do
        render json: {
          success: result.success,
          message: result.message,
          combat_log: result.combat_log,
          battle_status: result.battle&.status,
          rewards: result.rewards
        }
      end
    end
  end

  # GET /combat/skills
  # Get available combat skills
  def skills
    @skills = Game::Combat::SkillExecutor.available_skills(current_character)

    respond_to do |format|
      format.html { render partial: "combat/skills", locals: {skills: @skills} }
      format.json { render json: {skills: @skills} }
    end
  end

  # POST /combat/flee
  # Attempt to flee from combat
  def flee
    unless @battle
      return respond_with_error("Not in combat")
    end

    service = Game::Combat::PveEncounterService.new(current_character, nil)
    result = service.process_action!(action_type: :flee)

    respond_to do |format|
      if result.success && result.battle&.completed?
        format.html { redirect_to world_path, notice: "You escaped!" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("main_content", partial: "world/map")
        end
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("combat-log", partial: "combat/log_entries", locals: {entries: result.combat_log}),
            turbo_stream.replace("combat-status", partial: "combat/status", locals: {battle: result.battle})
          ]
        end
      end
      format.json { render json: {success: result.success, message: result.message, combat_log: result.combat_log} }
    end
  end

  private

  def set_battle
    @battle = current_character.battle_participants
      .joins(:battle)
      .where(battles: {status: :active})
      .first&.battle
  end

  def setup_battle_view_variables
    @player_participant = @battle.battle_participants.find_by(team: "player")
    @enemy_participant = @battle.battle_participants.find_by(team: "enemy")
    @combat_log = @battle.combat_log_entries.order(created_at: :desc).limit(10)

    # Action availability
    @can_act = @battle.active? && @player_participant&.is_alive
    @available_skills = @can_act ? Game::Combat::SkillExecutor.available_skills(current_character) : []
    @available_attacks = default_attacks
    @available_blocks = default_blocks

    # Team display (for group battles)
    @team_alpha = @battle.battle_participants.where(team: "player")
    @team_beta = @battle.battle_participants.where(team: "enemy")
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

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: {alert: message}) }
      format.json { render json: {success: false, error: message}, status: :unprocessable_entity }
    end
  end
end

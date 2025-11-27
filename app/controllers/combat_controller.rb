# frozen_string_literal: true

# Handles PvE combat encounters from the world map
class CombatController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_battle, only: %i[show action flee]

  # GET /combat
  # Show current combat status
  def show
    if @battle
      @player_participant = @battle.battle_participants.find_by(team: "player")
      @enemy_participant = @battle.battle_participants.find_by(team: "enemy")
      @combat_log = @battle.combat_log_entries.order(created_at: :desc).limit(10)
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
          render turbo_stream: [
            turbo_stream.replace("game-main", partial: "combat/battle", locals: { battle: result.battle }),
            turbo_stream.append("combat-log", partial: "combat/log_entries", locals: { entries: result.combat_log })
          ]
        end
        format.json { render json: { success: true, battle_id: result.battle.id, message: result.message } }
      else
        format.html { redirect_to world_path, alert: result.message }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: result.message }) }
        format.json { render json: { success: false, error: result.message }, status: :unprocessable_entity }
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
          turbo_stream.append("combat-log", partial: "combat/log_entries", locals: { entries: result.combat_log })
        ]

        if result.battle&.completed?
          streams << turbo_stream.replace("combat-actions", partial: "combat/result", locals: { result: result })
        else
          streams << turbo_stream.replace("combat-status", partial: "combat/status", locals: { battle: result.battle })
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
          render turbo_stream: turbo_stream.replace("game-main", partial: "world/map")
        end
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("combat-log", partial: "combat/log_entries", locals: { entries: result.combat_log }),
            turbo_stream.replace("combat-status", partial: "combat/status", locals: { battle: result.battle })
          ]
        end
      end
      format.json { render json: { success: result.success, message: result.message, combat_log: result.combat_log } }
    end
  end

  private

  def set_battle
    @battle = current_character.battle_participants
      .joins(:battle)
      .where(battles: { status: :active })
      .first&.battle
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: message }) }
      format.json { render json: { success: false, error: message }, status: :unprocessable_entity }
    end
  end
end

# frozen_string_literal: true

# Controller for dungeon instances.
#
# Manages dungeon discovery, entry, progress, and completion.
#
class DungeonsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_dungeon_template, only: [:show, :create_instance]
  before_action :set_dungeon_instance, only: [:instance, :enter_encounter, :complete_encounter, :leave]

  # GET /dungeons
  # List available dungeons
  def index
    @dungeon_templates = DungeonTemplate.accessible_by(current_character).order(:min_level)
    @active_instances = DungeonInstance.active_for_party(current_party).includes(:dungeon_template)
  end

  # GET /dungeons/:id
  # Show dungeon details
  def show
    @encounters = @dungeon_template.encounter_templates.order(:sequence)
    @loot_preview = @dungeon_template.loot_table&.first(5) || []
    @can_enter = can_enter_dungeon?(@dungeon_template)
  end

  # POST /dungeons/:id/instances
  # Create a new dungeon instance
  def create_instance
    unless current_party
      return redirect_to dungeon_path(@dungeon_template), alert: "You need a party to enter dungeons."
    end

    unless party_leader?
      return redirect_to dungeon_path(@dungeon_template), alert: "Only the party leader can start a dungeon."
    end

    @instance = DungeonInstance.new(
      dungeon_template: @dungeon_template,
      party: current_party,
      leader: current_character,
      difficulty: params[:difficulty] || :normal
    )

    if @instance.save && @instance.start!
      redirect_to dungeon_instance_path(@instance), notice: "Dungeon instance created!"
    else
      redirect_to dungeon_path(@dungeon_template), alert: @instance.errors.full_messages.to_sentence
    end
  end

  # GET /dungeon_instances/:id
  # Show active dungeon instance
  def instance
    authorize @dungeon_instance
    @current_encounter = @dungeon_instance.current_encounter
    @party_members = @dungeon_instance.party.active_members.includes(user: :character)
    @checkpoints = @dungeon_instance.dungeon_progress_checkpoints
  end

  # POST /dungeon_instances/:id/enter_encounter
  def enter_encounter
    authorize @dungeon_instance, :play?

    encounter = @dungeon_instance.dungeon_encounters.find(params[:encounter_id])

    if @dungeon_instance.advance_to_encounter!(encounter)
      redirect_to dungeon_instance_path(@dungeon_instance), notice: "Entering #{encounter.name}..."
    else
      redirect_to dungeon_instance_path(@dungeon_instance), alert: "Cannot enter this encounter."
    end
  end

  # POST /dungeon_instances/:id/complete_encounter
  def complete_encounter
    authorize @dungeon_instance, :play?

    encounter = @dungeon_instance.current_encounter
    success = params[:success] == "true"

    @dungeon_instance.complete_encounter!(encounter, success: success)

    if @dungeon_instance.completed?
      redirect_to dungeons_path, notice: "🏆 Dungeon completed!"
    elsif @dungeon_instance.failed?
      redirect_to dungeons_path, alert: "💀 Dungeon failed. Better luck next time!"
    else
      redirect_to dungeon_instance_path(@dungeon_instance)
    end
  end

  # POST /dungeon_instances/:id/leave
  def leave
    authorize @dungeon_instance, :play?

    if party_leader?
      @dungeon_instance.update!(status: :failed)
      redirect_to dungeons_path, notice: "Left the dungeon. Instance closed."
    else
      # Just remove from party
      redirect_to dungeons_path, notice: "Left the dungeon."
    end
  end

  private

  def set_dungeon_template
    @dungeon_template = DungeonTemplate.find(params[:id])
  end

  def set_dungeon_instance
    @dungeon_instance = DungeonInstance.find(params[:id])
  end

  def current_party
    @current_party ||= current_user.parties
      .joins(:party_memberships)
      .where(party_memberships: {user_id: current_user.id, status: :active})
      .first
  end

  def party_leader?
    current_party&.leader == current_user
  end

  def can_enter_dungeon?(template)
    return false unless current_party
    return false if current_character.level < template.min_level
    return false if template.max_level.present? && current_character.level > template.max_level
    return false if template.required_quest.present? && !quest_completed?(template.required_quest)

    true
  end

  def quest_completed?(quest_key)
    current_character.quest_assignments.joins(:quest).exists?(quests: {key: quest_key}, status: :completed)
  end
end

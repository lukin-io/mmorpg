# frozen_string_literal: true

# Manages skill tree display and ability unlock flows.
#
# @example View character skill tree
#   GET /skill_trees
#
# @example Unlock a skill node
#   POST /skill_trees/:id/unlock
#
class SkillTreesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_skill_tree, only: [:show, :unlock]

  # GET /skill_trees
  # Shows all skill trees available for the character's class
  def index
    @skill_trees = current_character.character_class.skill_trees.includes(:skill_nodes)
    @unlocked_skills = current_character.character_skills.includes(:skill_node).index_by { |cs| cs.skill_node_id }
    @available_points = current_character.available_skill_points
  end

  # GET /skill_trees/:id
  # Shows a specific skill tree with nodes
  def show
    authorize @skill_tree
    @nodes = @skill_tree.skill_nodes.order(:tier, :id)
    @unlocked_skills = current_character.character_skills.includes(:skill_node).index_by { |cs| cs.skill_node_id }
    @available_points = current_character.available_skill_points
  end

  # POST /skill_trees/:id/unlock
  # Unlocks a skill node for the character
  def unlock
    authorize @skill_tree, :unlock?
    node = @skill_tree.skill_nodes.find(params[:node_id])

    service = Players::Progression::SkillUnlockService.new(
      character: current_character,
      skill_node: node
    )

    if service.unlock!
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("skill_node_#{node.id}", partial: "skill_trees/node_frame", locals: {node: node, unlocked: true, can_unlock: false}),
            turbo_stream.replace("skill_points_display", partial: "skill_trees/points_panel", locals: {points: current_character.reload.available_skill_points}),
            turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :success, message: "Unlocked #{node.name}!"})
          ]
        end
        format.html { redirect_to @skill_tree, notice: "Unlocked #{node.name}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :alert, message: service.errors.full_messages.to_sentence})
        end
        format.html { redirect_to @skill_tree, alert: service.errors.full_messages.to_sentence }
      end
    end
  end

  # POST /skill_trees/respec
  # Resets all skill points
  def respec
    authorize SkillTree, :respec?

    service = Players::Progression::RespecService.new(character: current_character)

    if service.respec!
      redirect_to skill_trees_path, notice: "Skills reset! You have #{current_character.reload.available_skill_points} points to spend."
    else
      redirect_to skill_trees_path, alert: service.errors.full_messages.to_sentence
    end
  end

  private

  def set_skill_tree
    @skill_tree = SkillTree.find(params[:id])
  end
end

# frozen_string_literal: true

# Helpers for skill tree views.
module SkillTreesHelper
  TREE_ICONS = {
    "combat" => "⚔️",
    "magic" => "✨",
    "defense" => "🛡️",
    "utility" => "🔧",
    "support" => "💚"
  }.freeze

  NODE_ICONS = {
    "passive" => "◆",
    "active" => "★",
    "ultimate" => "🌟",
    "utility" => "⚙️"
  }.freeze

  def skill_tree_icon(tree)
    TREE_ICONS[tree.tree_type] || "📚"
  end

  def skill_node_icon(node)
    NODE_ICONS[node.node_type] || "●"
  end

  # Check if a node can be unlocked by the character
  #
  # @param node [SkillNode]
  # @param unlocked_skills [Hash] node_id => CharacterSkill
  # @param available_points [Integer]
  # @return [Boolean]
  def can_unlock_node?(node, unlocked_skills, available_points)
    return false if unlocked_skills[node.id].present?
    return false if available_points < node.point_cost
    return false if current_character.level < node.required_level

    # Check prerequisites
    return true if node.prerequisite_node_ids.blank?

    node.prerequisite_node_ids.all? { |prereq_id| unlocked_skills[prereq_id].present? }
  end
end

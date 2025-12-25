# frozen_string_literal: true

# SkillNode represents an individual ability/passive unlock step.
class SkillNode < ApplicationRecord
  NODE_TYPES = %w[passive active ultimate utility].freeze

  belongs_to :skill_tree
  has_many :character_skills, dependent: :destroy

  validates :key, :name, presence: true
  validates :node_type, inclusion: {in: NODE_TYPES}

  def description
    requirements["description"].presence || effects["description"].presence || ""
  end

  def required_level
    requirements.fetch("level", 0).to_i
  end

  def point_cost
    resource_cost.fetch("skill_points", 1).to_i
  end

  def prerequisite_node_ids
    Array(requirements["prerequisite_node_ids"]).map(&:to_i)
  end
end

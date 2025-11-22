# frozen_string_literal: true

# SkillNode represents an individual ability/passive unlock step.
class SkillNode < ApplicationRecord
  NODE_TYPES = %w[passive active ultimate utility].freeze

  belongs_to :skill_tree
  has_many :character_skills, dependent: :destroy

  validates :key, :name, presence: true
  validates :node_type, inclusion: {in: NODE_TYPES}
end

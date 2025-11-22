# frozen_string_literal: true

# SkillTree groups tiered unlocks per character class.
class SkillTree < ApplicationRecord
  belongs_to :character_class
  has_many :skill_nodes, dependent: :destroy

  validates :name, presence: true
end

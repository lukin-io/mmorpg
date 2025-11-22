# frozen_string_literal: true

class QuestObjective < ApplicationRecord
  belongs_to :quest

  validates :objective_type, presence: true
  validates :position, numericality: {greater_than: 0}
end

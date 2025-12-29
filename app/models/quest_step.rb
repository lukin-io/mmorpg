# frozen_string_literal: true

# QuestStep stores authored narrative beats (dialogue, travel, combat, cutscene)
# and optional branching outcomes that modify reputation, unlock future quests,
# or trigger map overlays. Quest objectives continue to represent mechanical
# requirements, while QuestStep focuses purely on narrative pacing.
class QuestStep < ApplicationRecord
  STEP_TYPES = {
    dialogue: "dialogue",
    travel: "travel",
    combat: "combat",
    cutscene: "cutscene",
    objective: "objective"
  }.freeze

  belongs_to :quest

  validates :position, numericality: {greater_than: 0}
  validates :step_type, inclusion: {in: STEP_TYPES.values}

  scope :ordered, -> { order(:position) }

  def step_type?(type)
    step_type == STEP_TYPES.fetch(type.to_sym)
  end

  def choices
    Array.wrap(branching_outcomes["choices"])
  end

  def requires_confirmation?
    !step_type?(:objective)
  end

  def consequence_for(choice_key)
    branching_outcomes.fetch("consequences", {}).fetch(choice_key, {})
  end
end

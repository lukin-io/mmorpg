# frozen_string_literal: true

# QuestChapter groups quests within a chain into gated story beats. Each chapter
# defines the minimum level/reputation/faction alignment required to progress
# deeper into the storyline and optionally references a cutscene that should
# unlock upon completion.
class QuestChapter < ApplicationRecord
  belongs_to :quest_chain
  has_many :quests, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :position, numericality: {greater_than: 0}
  validates :level_gate, numericality: {greater_than: 0}
  validates :reputation_gate, numericality: {greater_than_or_equal_to: 0}

  scope :ordered, -> { order(:position) }

  def gating_payload
    {
      min_level: level_gate,
      min_reputation: reputation_gate,
      faction_alignment: faction_alignment
    }.compact
  end
end

# frozen_string_literal: true

class Quest < ApplicationRecord
  enum :quest_type, {
    main_story: 0,
    side: 1,
    daily: 2,
    weekly: 3,
    dynamic: 4,
    raid: 5,
    event: 6
  }

  enum :difficulty_tier, {
    story: 0,
    veteran: 1,
    elite: 2,
    legendary: 3
  }

  belongs_to :quest_chain, optional: true
  belongs_to :quest_chapter, optional: true
  has_many :quest_objectives, dependent: :destroy
  has_many :quest_steps, dependent: :destroy
  has_many :quest_assignments, dependent: :destroy
  has_many :cutscene_events, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :sequence, numericality: {greater_than: 0}
  validates :recommended_party_size, numericality: {greater_than: 0}
  validates :min_level, numericality: {greater_than: 0}
  validates :min_reputation, numericality: {greater_than_or_equal_to: 0}

  scope :chronological, lambda {
    left_outer_joins(:quest_chapter)
      .order(Arel.sql("COALESCE(quest_chapters.position, quests.chapter) ASC"))
      .order(:sequence)
  }
  scope :by_difficulty, -> { order(:difficulty_tier, :recommended_party_size) }
  scope :active, -> { where(active: true) }

  def next_in_chain
    return unless quest_chain

    quest_chain.quests.where("sequence > ?", sequence).order(:sequence).first
  end

  def gating_requirements
    {
      min_level: min_level,
      min_reputation: min_reputation,
      faction_alignment: quest_chapter&.faction_alignment
    }.compact
  end

  def repeatable_template?
    repeatable? || daily? || weekly?
  end
end

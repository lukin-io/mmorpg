# frozen_string_literal: true

class QuestAssignment < ApplicationRecord
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2,
    failed: 3,
    expired: 4
  }

  belongs_to :quest
  belongs_to :character

  validates :status, presence: true

  scope :active, -> { where(status: [:pending, :in_progress]) }
  scope :completed, -> { where(status: :completed) }
  scope :repeatable_templates, lambda {
    joins(:quest).where(
      "quests.repeatable = :repeatable OR quests.quest_type IN (:quest_types)",
      repeatable: true,
      quest_types: [Quest.quest_types[:daily], Quest.quest_types[:weekly]]
    )
  }

  delegate :quest_type, :difficulty_tier, :recommended_party_size, :repeatable_template?, to: :quest

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def rewards_claimed?
    rewards_claimed_at.present?
  end

  def abandon!(reason:)
    update!(status: :failed, abandoned_at: Time.current, abandon_reason: reason)
  end

  def story_progress
    progress.deep_dup
  end

  def story_decisions
    story_progress.fetch("decisions", {})
  end

  def current_step_position
    story_progress.fetch("current_step_position", 1).to_i
  end

  def story_complete?
    story_progress["completed"].present?
  end

  def story_flags
    Array(metadata.fetch("story_flags", []))
  end

  def record_story_progress!(attrs)
    self.progress = story_progress.merge(attrs.stringify_keys)
    save!
  end

  def append_story_flags!(flags)
    merged = (story_flags + Array(flags)).uniq
    update!(metadata: metadata.merge("story_flags" => merged))
  end

  def repeatable_assignment?
    repeatable_template?
  end

  def filter_key
    return :completed if completed?
    return :repeatable if repeatable_assignment?

    :active
  end
end

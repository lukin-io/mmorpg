# frozen_string_literal: true

class CraftingJob < ApplicationRecord
  QUALITY_TIERS = {
    common: "common",
    uncommon: "uncommon",
    rare: "rare",
    epic: "epic",
    legendary: "legendary"
  }.freeze

  enum :status, {
    queued: 0,
    in_progress: 1,
    completed: 2,
    failed: 3
  }
  enum :quality_tier, QUALITY_TIERS, prefix: :quality_tier

  belongs_to :user
  belongs_to :character
  belongs_to :recipe
  belongs_to :crafting_station

  validates :started_at, :completes_at, presence: true
  validates :batch_quantity, numericality: {greater_than: 0}

  scope :active, -> { where(status: [:queued, :in_progress]) }
  scope :for_character, ->(character) { where(character:) }

  broadcasts_to ->(job) { ["crafting_jobs", job.character_id] }, inserts_by: :append

  delegate :profession, to: :recipe

  def progress_percent(now: Time.current)
    return 0 if completes_at <= started_at
    return 0 if now <= started_at
    return 100 if now >= completes_at

    elapsed = now - started_at
    total = completes_at - started_at
    ((elapsed / total) * 100).round
  end

  def portable?
    portable_penalty_applied
  end
end

# frozen_string_literal: true

class CraftingJob < ApplicationRecord
  enum :status, {
    queued: 0,
    in_progress: 1,
    completed: 2,
    failed: 3
  }

  belongs_to :user
  belongs_to :recipe
  belongs_to :crafting_station

  validates :started_at, :completes_at, presence: true

  scope :active, -> { where(status: [:queued, :in_progress]) }
end


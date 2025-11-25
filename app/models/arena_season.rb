# frozen_string_literal: true

class ArenaSeason < ApplicationRecord
  STATUSES = {
    scheduled: 0,
    live: 1,
    completed: 2,
    archived: 3
  }.freeze

  enum :status, STATUSES

  has_many :arena_matches, dependent: :nullify

  validates :name, :slug, :starts_at, presence: true

  scope :current, -> { live.where("starts_at <= ? AND (ends_at IS NULL OR ends_at >= ?)", Time.current, Time.current) }
end

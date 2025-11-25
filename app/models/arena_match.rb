# frozen_string_literal: true

class ArenaMatch < ApplicationRecord
  STATUSES = {
    pending: 0,
    matching: 1,
    live: 2,
    completed: 3,
    cancelled: 4
  }.freeze

  MATCH_TYPES = {
    duel: 0,
    skirmish: 1,
    tournament: 2
  }.freeze

  enum :status, STATUSES
  enum :match_type, MATCH_TYPES

  belongs_to :arena_season, optional: true
  belongs_to :arena_tournament, optional: true
  belongs_to :zone, optional: true

  has_many :arena_participations, dependent: :destroy

  validates :match_type, presence: true

  before_create :assign_spectator_code

  scope :recent, -> { order(created_at: :desc) }

  def broadcast_channel
    "arena:match:#{id}"
  end

  private

  def assign_spectator_code
    self.spectator_code ||= SecureRandom.alphanumeric(8).upcase
  end
end

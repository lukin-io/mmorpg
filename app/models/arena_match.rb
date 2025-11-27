# frozen_string_literal: true

# Arena match record with real-time broadcasting support
# Tracks fight status, participants, and results
#
# @example Create a match from applications
#   Arena::Matchmaker.new.create_match(application1, application2)
#
# @example Subscribe to match updates
#   ArenaMatchChannel.subscribed(match_id: match.id)
#
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
    tournament: 2,
    team_battle: 3, # renamed from 'group' to avoid ActiveRecord conflict
    sacrifice: 4
  }.freeze

  enum :status, STATUSES
  enum :match_type, MATCH_TYPES

  belongs_to :arena_season, optional: true
  belongs_to :arena_tournament, optional: true
  belongs_to :arena_room, optional: true
  belongs_to :zone, optional: true

  has_many :arena_participations, dependent: :destroy
  has_many :arena_applications, dependent: :nullify
  has_many :characters, through: :arena_participations

  validates :match_type, presence: true

  before_create :assign_spectator_code

  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: [:pending, :matching, :live]) }

  # ActionCable broadcast channel name
  #
  # @return [String] channel name for this match
  def broadcast_channel
    "arena:match:#{id}"
  end

  # Get participants for a specific team
  #
  # @param team [String] team identifier ("a" or "b")
  # @return [ActiveRecord::Relation] participations for that team
  def team_participants(team)
    arena_participations.where(team: team)
  end

  # Check if match is still active (can receive actions)
  #
  # @return [Boolean] true if match accepts combat actions
  def active?
    pending? || matching? || live?
  end

  # Duration of the match in seconds
  #
  # @return [Integer, nil] seconds elapsed, or nil if not started
  def duration
    return nil unless started_at
    end_time = ended_at || Time.current
    (end_time - started_at).to_i
  end

  private

  def assign_spectator_code
    self.spectator_code ||= SecureRandom.alphanumeric(8).upcase
  end
end

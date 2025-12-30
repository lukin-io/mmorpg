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
  DEFAULT_TURN_TIMEOUT = 300 # 5 minutes

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
  scope :timed_out, -> {
    live.where("current_turn_started_at < ?", DEFAULT_TURN_TIMEOUT.seconds.ago)
  }

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

  # Check if the current turn has timed out
  #
  # @return [Boolean] true if turn has exceeded timeout
  def turn_timed_out?
    return false unless live?
    return false unless current_turn_started_at

    timeout = turn_timeout_seconds || DEFAULT_TURN_TIMEOUT
    Time.current > (current_turn_started_at + timeout.seconds)
  end

  # Seconds remaining until turn times out
  #
  # @return [Integer, nil] seconds remaining, or nil if not in turn
  def seconds_until_timeout
    return nil unless live?
    return nil unless current_turn_started_at

    timeout = turn_timeout_seconds || DEFAULT_TURN_TIMEOUT
    deadline = current_turn_started_at + timeout.seconds
    remaining = (deadline - Time.current).to_i
    [remaining, 0].max
  end

  # Start a new turn with timeout tracking
  #
  # @param team [String] which team's turn ("a" or "b")
  # @return [Boolean] true if turn started
  def start_turn!(team: nil)
    update!(
      current_turn_started_at: Time.current,
      current_turn_number: (current_turn_number || 0) + 1,
      current_turn_team: team
    )

    # Schedule timeout check
    schedule_timeout_check

    true
  end

  # Advance to the next turn after submission or timeout
  #
  # @param timed_out [Boolean] whether this turn timed out
  # @return [Boolean] true if advanced successfully
  def advance_turn!(timed_out: false)
    self.timed_out = timed_out if timed_out

    # Switch teams if applicable
    next_team = (current_turn_team == "a") ? "b" : "a"

    update!(
      current_turn_started_at: Time.current,
      current_turn_number: (current_turn_number || 0) + 1,
      current_turn_team: next_team
    )

    # Schedule timeout check for new turn
    schedule_timeout_check

    true
  end

  # Schedule a job to check for turn timeout
  #
  # @return [void]
  def schedule_timeout_check
    timeout = turn_timeout_seconds || DEFAULT_TURN_TIMEOUT
    ArenaTurnTimeoutJob.set(wait: timeout.seconds).perform_later(match_id: id)

    # Also schedule warning at 30 seconds remaining
    if timeout > 30
      ArenaTurnTimeoutWarningJob.set(wait: (timeout - 30).seconds)
        .perform_later(match_id: id, seconds_remaining: 30)
    end
  end

  private

  def assign_spectator_code
    self.spectator_code ||= SecureRandom.alphanumeric(8).upcase
  end
end

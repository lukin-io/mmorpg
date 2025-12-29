# frozen_string_literal: true

# Battle persists PvE/PvP encounters, initiative order, and combat status.
#
# Combat modes:
# - simultaneous: All participants submit actions, then resolve together
# - sequential: Each participant acts in turn order
#
# Turn timer:
# - turn_timeout_seconds: Time limit per turn (default 300 = 5 minutes)
# - turn_timer_ends_at: When current turn times out (auto-forfeit)
class Battle < ApplicationRecord
  PVP_MODES = %w[duel skirmish arena clan].freeze
  COMBAT_MODES = %w[simultaneous sequential].freeze

  enum :battle_type, {
    pve: 0,
    pvp: 1,
    arena: 2
  }

  enum :status, {
    pending: 0,
    active: 1,
    completed: 2
  }

  belongs_to :zone, optional: true
  belongs_to :initiator, class_name: "Character"
  has_many :battle_participants, dependent: :destroy
  has_many :combat_log_entries, dependent: :destroy
  has_one :combat_analytics_report, dependent: :destroy

  validates :turn_number, numericality: {greater_than: 0}
  validates :pvp_mode, inclusion: {in: PVP_MODES}, allow_nil: true
  validates :combat_mode, inclusion: {in: COMBAT_MODES}, allow_nil: true

  before_create :generate_share_token
  before_create :set_default_combat_settings

  # Scopes for finding battles by state
  scope :with_expiring_timer, -> {
    where("turn_timer_ends_at IS NOT NULL AND turn_timer_ends_at < ? AND status = ?", Time.current, statuses[:active])
  }

  scope :simultaneous, -> { where(combat_mode: "simultaneous") }
  scope :sequential, -> { where(combat_mode: "sequential") }

  # Find battle by share token for public access
  def self.find_by_share_token!(token)
    find_by!(share_token: token)
  end

  # Generate a shareable public URL
  def public_url
    return nil unless share_token.present?

    Rails.application.routes.url_helpers.public_battle_log_url(share_token, host: default_host)
  end

  # Shareable path (for internal links)
  def public_path
    return nil unless share_token.present?

    Rails.application.routes.url_helpers.public_battle_log_path(share_token)
  end

  def next_sequence_for(round_number)
    combat_log_entries.where(round_number:).maximum(:sequence).to_i + 1
  end

  def ladder_type
    return "arena" if battle_type == "arena"
    return pvp_mode if pvp_mode.present?

    nil
  end

  # Regenerate share token (for privacy)
  def regenerate_share_token!
    update!(share_token: generate_unique_token)
  end

  # Check if all participants have submitted their turn
  #
  # @return [Boolean]
  def all_participants_ready?
    return true if combat_mode == "sequential"

    battle_participants.alive.all? do |p|
      p.turn_submitted_at.present? || p.participant_type == "npc"
    end
  end

  # Start turn timer
  #
  # @param seconds [Integer] override timeout (default uses turn_timeout_seconds)
  def start_turn_timer!(seconds: nil)
    timeout = seconds || turn_timeout_seconds || 300
    update!(turn_timer_ends_at: timeout.seconds.from_now)
  end

  # Check if turn timer has expired
  #
  # @return [Boolean]
  def turn_timer_expired?
    return false unless turn_timer_ends_at

    turn_timer_ends_at < Time.current
  end

  # Seconds remaining on turn timer
  #
  # @return [Integer, nil]
  def turn_timer_remaining
    return nil unless turn_timer_ends_at
    return 0 if turn_timer_expired?

    (turn_timer_ends_at - Time.current).to_i
  end

  # Get team participants
  #
  # @param team [String] team name ("alpha" or "beta")
  # @return [ActiveRecord::Relation]
  def team(team_name)
    battle_participants.where(team: team_name)
  end

  # Check if battle is in simultaneous mode
  #
  # @return [Boolean]
  def simultaneous?
    combat_mode == "simultaneous"
  end

  # Get current round's combat log
  #
  # @return [Array<CombatLogEntry>]
  def current_round_log
    combat_log_entries.where(round_number: round_number || 1).order(:sequence)
  end

  # Broadcast channel name
  #
  # @return [String]
  def broadcast_channel
    "battle:#{id}"
  end

  private

  def set_default_combat_settings
    self.combat_mode ||= "simultaneous"
    self.turn_timeout_seconds ||= 300
    self.action_points_per_turn ||= 80
    self.max_mana_per_turn ||= 50
    self.round_number ||= 1
  end

  def generate_share_token
    self.share_token ||= generate_unique_token
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(12)
      break token unless Battle.exists?(share_token: token)
    end
  end

  def default_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end

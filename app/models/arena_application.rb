# frozen_string_literal: true

# Arena fight application waiting for opponents
# Players submit applications with fight parameters, then accept/decline pending fights.
#
# @example Create a duel application
#   ArenaApplication.create!(
#     arena_room: room,
#     applicant: character,
#     fight_type: :duel,
#     fight_kind: :free,
#     timeout_seconds: 180,
#     trauma_percent: 30
#   )
#
# @example Find available applications for a character
#   ArenaApplication.open.available_for(character)
#
class ArenaApplication < ApplicationRecord
  FIGHT_TYPES = {
    duel: 0,        # 1v1 combat
    team_battle: 1, # Team vs Team (renamed from 'group' to avoid ActiveRecord conflict)
    sacrifice: 2    # Free-for-all melee
  }.freeze

  FIGHT_KINDS = {
    no_weapons: 0,        # Bare-handed combat only
    free: 1,              # Freestyle
    alignment_vs_alignment: 3,
    no_artifacts: 7,
    limited_artifacts: 8
  }.freeze

  STATUSES = {
    open: 0,       # Waiting for opponents
    matched: 1,    # Found opponent, waiting to start
    started: 2,    # Fight in progress
    expired: 3,    # Timed out
    cancelled: 4   # Withdrawn by applicant
  }.freeze

  VALID_TIMEOUTS = [120, 180, 240, 300].freeze
  VALID_TRAUMA_PERCENTS = [10, 30, 50, 80].freeze
  MIN_HP_PERCENT_FOR_ARENA = 50 # Minimum HP% required to accept fights

  enum :fight_type, FIGHT_TYPES
  enum :fight_kind, FIGHT_KINDS
  enum :status, STATUSES

  belongs_to :arena_room
  belongs_to :applicant, class_name: "Character", optional: true
  belongs_to :npc_template, optional: true
  belongs_to :matched_with, class_name: "ArenaApplication", optional: true
  belongs_to :arena_match, optional: true

  validates :timeout_seconds, inclusion: {in: VALID_TIMEOUTS}
  validates :trauma_percent, inclusion: {in: VALID_TRAUMA_PERCENTS}
  validate :applicant_can_access_room, on: :create, unless: :npc_application?
  validate :npc_can_appear_in_room, on: :create, if: :npc_application?
  validate :group_params_valid, if: :team_battle?
  validate :has_applicant_or_npc

  before_create :set_expiration

  scope :open, -> { where(status: :open) }
  scope :matched, -> { where(status: :matched) }
  scope :active, -> { where(status: [:open, :matched]) }
  scope :expired_and_unprocessed, -> { open.where("expires_at < ?", Time.current) }
  scope :from_players, -> { where.not(applicant_id: nil) }
  scope :from_npcs, -> { where.not(npc_template_id: nil) }
  scope :npc_applications, -> { from_npcs }

  # Find applications that a character can accept
  #
  # @param character [Character] the character looking for fights
  # @return [ActiveRecord::Relation] matching applications
  scope :available_for, ->(character) {
    open
      .where("team_level_min IS NULL OR team_level_min <= ?", character.level)
      .where("team_level_max IS NULL OR team_level_max >= ?", character.level)
      .where.not(applicant: character)
  }

  # Time remaining until this application expires
  #
  # @return [Integer, nil] seconds until expiration, or nil if already expired
  def time_until_expiration
    return nil unless expires_at
    [(expires_at - Time.current).to_i, 0].max
  end

  # Time remaining until matched fight starts
  #
  # @return [Integer, nil] seconds until start, or nil if not matched
  def time_until_start
    return nil unless matched? && starts_at
    [(starts_at - Time.current).to_i, 0].max
  end

  # Check if this application can be accepted by a character
  #
  # @param character [Character] the character wanting to accept
  # @return [Boolean] true if character can accept this application
  def acceptable_by?(character)
    return false unless open?
    return false if applicant == character
    return false unless arena_room.accessible_by?(character)
    return false if alignment_restricted? && !alignment_matches?(character)
    return false unless character_hp_sufficient?(character)

    level_matches?(character)
  end

  # Check if character has enough HP to fight
  # Message: "Recover before fighting, you are too weakened!"
  #
  # @param character [Character] the character to check
  # @return [Boolean] true if character has enough HP
  def character_hp_sufficient?(character)
    return true if character.max_hp.nil? || character.max_hp.zero?

    hp_percent = (character.current_hp.to_f / character.max_hp * 100).round
    hp_percent >= MIN_HP_PERCENT_FOR_ARENA
  end

  # Get rejection reason for a character who cannot accept
  #
  # @param character [Character] the character to check
  # @return [String, nil] reason why character cannot accept, or nil if they can
  def rejection_reason_for(character)
    return "Application is not open" unless open?
    return "Cannot accept your own application" if applicant == character
    return "Cannot access this arena room" unless arena_room.accessible_by?(character)
    return "Alignment restriction not met" if alignment_restricted? && !alignment_matches?(character)
    return "Recover before fighting - you are too weakened! (Need #{MIN_HP_PERCENT_FOR_ARENA}% HP)" unless character_hp_sufficient?(character)
    return "Level requirement not met" unless level_matches?(character)

    nil
  end

  # Check if the fight has level restrictions
  #
  # @param character [Character] the character to check
  # @return [Boolean] true if character's level is in range
  def level_matches?(character)
    min = team_level_min || arena_room.level_min
    max = team_level_max || arena_room.level_max
    character.level.between?(min, max)
  end

  def alignment_restricted?
    alignment_vs_alignment?
  end

  def alignment_matches?(character)
    return true unless alignment_restricted?
    return false if applicant.alignment == Character::ALIGNMENTS[:none]
    return false if character.alignment == Character::ALIGNMENTS[:none]

    applicant.alignment != character.alignment
  end

  # Check if this is an NPC-created application
  #
  # @return [Boolean] true if application is from an NPC
  def npc_application?
    npc_template_id.present?
  end

  # Check if this is a player-created application
  #
  # @return [Boolean] true if application is from a player
  def player_application?
    applicant_id.present?
  end

  # Get the applicant name (works for both players and NPCs)
  #
  # @return [String] the applicant's name
  def applicant_name
    if npc_application?
      npc_template&.name || "Arena Bot"
    else
      applicant&.name || "Unknown"
    end
  end

  # Get the applicant level (works for both players and NPCs)
  #
  # @return [Integer] the applicant's level
  def applicant_level
    if npc_application?
      npc_template&.level || 0
    else
      applicant&.level || 1
    end
  end

  # Get AI behavior for NPC applications
  #
  # @return [String, nil] AI behavior or nil for player applications
  def npc_ai_behavior
    return nil unless npc_application?

    npc_template&.ai_behavior
  end

  private

  def set_expiration
    wait = wait_minutes || 10
    self.expires_at ||= Time.current + wait.minutes
  end

  def applicant_can_access_room
    return if arena_room.nil? || applicant.nil?

    unless arena_room.accessible_by?(applicant)
      errors.add(:applicant, "cannot access this arena room")
    end
  end

  def group_params_valid
    if team_count.nil? || team_count < 1
      errors.add(:team_count, "is required for group fights")
    end
    if enemy_count.nil? || enemy_count < 1
      errors.add(:enemy_count, "is required for group fights")
    end
  end

  def has_applicant_or_npc
    if applicant_id.blank? && npc_template_id.blank?
      errors.add(:base, "must have either an applicant or an NPC template")
    end
    if applicant_id.present? && npc_template_id.present?
      errors.add(:base, "cannot have both an applicant and an NPC template")
    end
  end

  def npc_can_appear_in_room
    return if arena_room.nil? || npc_template.nil?

    npc_rooms = npc_template.arena_rooms
    return if npc_rooms.empty? # Empty means NPC can appear anywhere

    unless npc_rooms.include?(arena_room.slug)
      errors.add(:npc_template, "cannot appear in this arena room")
    end
  end
end

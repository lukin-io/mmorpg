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
    alignment_vs_all: 4,
    closed: 6,
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
  AVAILABLE_FIGHT_TYPES = %w[duel team_battle].freeze
  VALID_WAIT_MINUTES = [5, 10, 15, 30, 45, 60].freeze
  DUEL_KINDS = %w[no_weapons no_artifacts limited_artifacts free].freeze
  GROUP_KINDS = (DUEL_KINDS + %w[alignment_vs_alignment alignment_vs_all closed]).freeze
  MIN_HP_PERCENT_FOR_ARENA = 50 # Minimum HP% required to accept fights

  enum :fight_type, FIGHT_TYPES
  enum :fight_kind, FIGHT_KINDS
  enum :status, STATUSES

  belongs_to :arena_room
  belongs_to :applicant, class_name: "Character", optional: true
  belongs_to :npc_template, optional: true
  belongs_to :matched_with, class_name: "ArenaApplication", optional: true
  belongs_to :arena_match, optional: true
  has_many :arena_application_memberships, dependent: :destroy

  validates :timeout_seconds, :trauma_percent, :wait_minutes, numericality: {only_integer: true}, allow_nil: true
  validates :timeout_seconds, inclusion: {in: VALID_TIMEOUTS}
  validates :trauma_percent, inclusion: {in: VALID_TRAUMA_PERCENTS}
  validate :applicant_can_access_room, on: :create, unless: :npc_application?
  validate :npc_can_appear_in_room, on: :create, if: :npc_application?
  validate :group_params_valid, if: :team_battle?
  validate :has_applicant_or_npc
  validate :fight_kind_available
  validates :fight_type, inclusion: {in: AVAILABLE_FIGHT_TYPES}, on: :create
  validates :wait_minutes, inclusion: {in: VALID_WAIT_MINUTES}, allow_nil: true

  before_create :set_expiration

  scope :open, -> { where(status: :open) }
  scope :matched, -> { where(status: :matched) }
  scope :active, -> {
    where(status: :open).or(
      where(status: :matched, arena_match_id: ArenaMatch.active.select(:id))
    )
  }
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
    return false unless open? && !deadline_passed?
    return %w[a b].any? { |team| group_rejection_reason(character, team:).nil? } if team_battle?
    return false if applicant == character
    return false unless arena_room.accessible_by?(character)
    return false if alignment_restricted? && !alignment_matches?(character)
    return false unless character_hp_sufficient?(character)
    return false if Arena::EquipmentRule.new(fight_kind).rejection_reason(character)

    level_matches?(character)
  end

  # Check if character has enough HP to fight
  # Message: "Recover before fighting, you are too weakened!"
  #
  # @param character [Character] the character to check
  # @return [Boolean] true if character has enough HP
  def character_hp_sufficient?(character)
    return false unless character && character.max_hp.to_i.positive?

    character.current_hp.to_i * 100 >= character.max_hp * MIN_HP_PERCENT_FOR_ARENA
  end

  # Get rejection reason for a character who cannot accept
  #
  # @param character [Character] the character to check
  # @return [String, nil] reason why character cannot accept, or nil if they can
  def rejection_reason_for(character)
    return "Application is closed" unless open?
    return "Application has expired" if deadline_passed?
    return "Choose an available group side" if team_battle?
    return "You cannot accept your own application" if applicant == character
    return "Arena room is unavailable" unless arena_room.accessible_by?(character)
    return "Alignment does not match" if alignment_restricted? && !alignment_matches?(character)
    return "Recover before fighting: minimum #{MIN_HP_PERCENT_FOR_ARENA}% HP" unless character_hp_sufficient?(character)
    return "Level does not match" unless level_matches?(character)
    Arena::EquipmentRule.new(fight_kind).rejection_reason(character)
  end

  def deadline_passed?(now: Time.current)
    expires_at.present? && now >= expires_at
  end

  def members_for(team)
    arena_application_memberships.select { |entry| entry.team == team }
  end

  def side_capacity(team)
    team == "a" ? team_count : enemy_count
  end

  def side_level_range(team)
    minimum, maximum = team == "a" ? [team_level_min, team_level_max] : [enemy_level_min, enemy_level_max]
    (minimum || arena_room.level_min)..(maximum || arena_room.level_max)
  end

  def member?(character)
    applicant_id == character.id || arena_application_memberships.any? { |entry| entry.character_id == character.id }
  end

  def group_rejection_reason(character, team:)
    return "Application is closed" unless open? && !deadline_passed?
    return "Choose a group side" unless team.in?(%w[a b])
    return "You already joined this application" if member?(character)
    return "Arena room is unavailable" unless arena_room.accessible_by?(character)
    return "This side is full" if members_for(team).size >= side_capacity(team).to_i
    return "Level does not match this side" unless side_level_range(team).cover?(character.level)
    return "Recover before fighting: minimum #{MIN_HP_PERCENT_FOR_ARENA}% HP" unless character_hp_sufficient?(character)
    if alignment_vs_alignment? || alignment_vs_all?
      return "Alignment does not match this side" unless group_alignment_matches?(character, team:)
    end
    Arena::EquipmentRule.new(fight_kind).rejection_reason(character)
  end

  def group_alignment_matches?(character, team:)
    return true if alignment_vs_all? && team == "b"
    return false if character.alignment == Character::ALIGNMENTS[:none]
    return character.alignment == applicant.alignment if team == "a"

    opponent_alignment = members_for("b").first&.character&.alignment
    character.alignment != applicant.alignment && (opponent_alignment.nil? || character.alignment == opponent_alignment)
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
    capacity = closed? ? 10 : 30
    %i[team_count enemy_count].each do |field|
      value = Integer(public_send("#{field}_before_type_cast").to_s, exception: false)
      errors.add(field, "must be between 1 and #{capacity}") unless value&.between?(1, capacity)
    end
    %w[team enemy].each do |side|
      minimum, maximum = %w[min max].map { |bound| Integer(public_send("#{side}_level_#{bound}_before_type_cast").to_s, exception: false) }
      unless minimum.is_a?(Integer) && maximum.is_a?(Integer) && minimum.between?(0, 33) && maximum.between?(minimum, 33)
        errors.add(:base, "#{side.humanize} levels must be an ordered range within 0-33")
      end
    end
    if applicant && team_level_min && team_level_max && !side_level_range("a").cover?(applicant.level)
      errors.add(:applicant, "must fit the first side's level range")
    end
  end

  def fight_kind_available
    available = team_battle? ? GROUP_KINDS : DUEL_KINDS
    errors.add(:fight_kind, "is unavailable for this mode") unless available.include?(fight_kind)
    if applicant && (alignment_vs_alignment? || alignment_vs_all?) && applicant.alignment == Character::ALIGNMENTS[:none]
      errors.add(:applicant, "requires an alignment for this fight")
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

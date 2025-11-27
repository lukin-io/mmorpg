# frozen_string_literal: true

# Arena room within arena complex with level/faction restrictions
# Room types: Training Hall, Trial Hall, faction halls, etc.
#
# @example Check if character can access room
#   room = ArenaRoom.find_by(slug: "training-hall")
#   room.accessible_by?(character) # => true/false
#
# @example Get active applications for a room
#   room.arena_applications.open.available_for(character)
#
class ArenaRoom < ApplicationRecord
  ROOM_TYPES = {
    training: 0,    # Levels 0-5, reduced penalties
    trial: 1,       # Levels 5-10, beginner competitive
    challenge: 2,   # Levels 5-33, open range duels
    initiation: 3,  # Levels 9-33, mid-level progression
    patron: 4,      # Levels 16-33, high-level competitive
    law: 5,         # Faction: Law alignment only
    light: 6,       # Faction: Light alignment only
    balance: 7,     # Faction: Neutral alignment only
    chaos: 8,       # Faction: Chaos alignment only
    dark: 9         # Faction: Dark alignment only
  }.freeze

  enum :room_type, ROOM_TYPES

  belongs_to :zone, optional: true
  has_many :arena_applications, dependent: :destroy
  has_many :arena_matches, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :level_min, :level_max, numericality: {greater_than_or_equal_to: 0}
  validates :max_concurrent_matches, numericality: {greater_than: 0}
  validate :level_range_valid

  scope :active, -> { where(active: true) }
  scope :for_level, ->(level) { where("level_min <= ? AND level_max >= ?", level, level) }

  # Check if a character can access this room
  #
  # @param character [Character] the character to check
  # @return [Boolean] true if character meets level and faction requirements
  def accessible_by?(character)
    return false unless active?
    return false unless character.level.between?(level_min, level_max)
    return false if faction_restriction.present? && character.faction_alignment != faction_restriction

    true
  end

  # Get current match count for capacity checking
  #
  # @return [Integer] number of active matches in this room
  def current_match_count
    arena_matches.where(status: [:pending, :matching, :live]).count
  end

  # Check if room has capacity for new matches
  #
  # @return [Boolean] true if room can accept new matches
  def has_capacity?
    current_match_count < max_concurrent_matches
  end

  # Get count of open applications waiting for opponents
  #
  # @return [Integer] number of open applications
  def open_application_count
    arena_applications.open.count
  end

  private

  def level_range_valid
    if level_min.present? && level_max.present? && level_min > level_max
      errors.add(:level_max, "must be greater than or equal to level_min")
    end
  end
end

# frozen_string_literal: true

# Arena room within arena complex with level/alignment restrictions.
#
# @example Check if character can access room
#   room = ArenaRoom.find_by(slug: "training")
#   room.accessible_by?(character) # => true/false
#
# @example Get active applications for a room
#   room.arena_applications.open.available_for(character)
#
class ArenaRoom < ApplicationRecord
  ROOM_TYPES = {
    help: 0,
    training: 1,
    trial: 2,
    initiation: 3,  # Levels 9-33, mid-level progression
    patron: 4,      # Levels 16-33, high-level competitive
    law: 5,
    light: 6,
    balance: 7,
    chaos: 8,
    dark: 9
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
  # @return [Boolean] true if character meets level and alignment requirements
  def accessible_by?(character)
    return false unless active?
    return false unless character.level.between?(level_min, level_max)
    return false if alignment_restriction.present? && character.alignment != alignment_restriction

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

  # Get human-readable text explaining why character cannot access this room
  #
  # @param character [Character] the character to check
  # @return [String] explanation of access requirement
  def access_requirement_text(character)
    return "Room is unavailable" unless active?

    unless character.level.between?(level_min, level_max)
      return "Requires level #{level_min}-#{level_max}; your level #{character.level}"
    end

    if alignment_restriction.present? && character.alignment != alignment_restriction
      return "Alignment does not match"
    end

    "Available"
  end

  private

  def level_range_valid
    if level_min.present? && level_max.present? && level_min > level_max
      errors.add(:level_max, "must be greater than or equal to level_min")
    end
  end
end

# frozen_string_literal: true

# Represents a character's state in a tactical match.
#
# Tracks position, HP, buffs/debuffs, and combat stats on the grid.
#
class TacticalParticipant < ApplicationRecord
  belongs_to :tactical_match
  belongs_to :character

  validates :grid_x, :grid_y, numericality: {greater_than_or_equal_to: 0}
  validates :current_hp, numericality: {greater_than_or_equal_to: 0}
  validates :movement_range, :attack_range, numericality: {greater_than: 0}

  scope :alive, -> { where(alive: true) }

  # Take damage and check for death
  def take_damage!(amount)
    reduced_damage = apply_defense(amount)
    new_hp = [current_hp - reduced_damage, 0].max

    update!(current_hp: new_hp, alive: new_hp.positive?)

    # Check for match end
    check_match_end! unless alive?

    reduced_damage
  end

  # Heal HP
  def heal!(amount)
    new_hp = [current_hp + amount, character.max_hp].min
    update!(current_hp: new_hp)
    new_hp - current_hp
  end

  # Check if can attack target
  def can_attack?(target_participant)
    return false unless alive? && target_participant.alive?

    distance = (grid_x - target_participant.grid_x).abs +
      (grid_y - target_participant.grid_y).abs

    distance <= attack_range
  end

  # Get attack damage
  def attack_damage
    base = character.stats.get(:strength).to_i * 2 + rand(1..10)
    base += buffs.fetch("attack_bonus", 0)
    base
  end

  # Apply defense reduction
  def apply_defense(incoming_damage)
    defense = character.stats.get(:vitality).to_i + cover_bonus
    defense += buffs.fetch("defense_bonus", 0)

    reduction = defense / 100.0
    (incoming_damage * (1 - reduction)).to_i
  end

  # Check if on cover tile
  def cover_bonus
    tile = tactical_match.grid_state&.dig(grid_y, grid_x)
    return 0 unless tile.is_a?(Hash) && tile["type"] == "cover"

    tile.fetch("defense_bonus", 0)
  end

  # Add buff
  def add_buff!(buff_key, value, duration: 3)
    new_buffs = buffs.merge(buff_key => value)
    new_buff_durations = buff_durations.merge(buff_key => duration)
    update!(buffs: new_buffs, buff_durations: new_buff_durations)
  end

  # Tick down buff durations
  def tick_buffs!
    new_durations = buff_durations.transform_values { |v| v - 1 }
    expired = new_durations.select { |_, v| v <= 0 }.keys

    new_buffs = buffs.except(*expired)
    new_durations = new_durations.except(*expired)

    update!(buffs: new_buffs, buff_durations: new_durations)
  end

  private

  def check_match_end!
    return if tactical_match.tactical_participants.alive.count > 1

    winner = tactical_match.tactical_participants.alive.first&.character
    tactical_match.declare_winner!(winner) if winner
  end
end

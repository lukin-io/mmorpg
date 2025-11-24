# frozen_string_literal: true

# GatheringNode represents resource nodes tied to professions and zones.
class GatheringNode < ApplicationRecord
  belongs_to :profession
  belongs_to :zone

  validates :resource_key, presence: true
  validates :difficulty, :respawn_seconds, numericality: {greater_than: 0}
  validates :group_bonus_percent, numericality: {greater_than_or_equal_to: 0}

  scope :available, -> { where("next_available_at IS NULL OR next_available_at <= ?", Time.current) }

  def available?
    next_available_at.nil? || next_available_at <= Time.current
  end

  def effective_respawn_seconds(party_size: 1)
    base = respawn_seconds
    biome_modifier =
      case zone.biome
      when "forest" then -5
      when "mountain" then 10
      when "city" then 20
      else
        0
      end
    party_bonus =
      if party_size > 1
        -(party_size * group_bonus_percent / 100.0 * base)
      else
        0
      end
    (base + biome_modifier + party_bonus).clamp(10, base * 2)
  end

  def mark_harvest!(party_size: 1)
    now = Time.current
    update!(
      last_harvested_at: now,
      next_available_at: now + effective_respawn_seconds(party_size: party_size).seconds
    )
  end
end

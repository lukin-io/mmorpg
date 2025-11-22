# frozen_string_literal: true

# GatheringNode represents resource nodes tied to professions and zones.
class GatheringNode < ApplicationRecord
  belongs_to :profession
  belongs_to :zone

  validates :resource_key, presence: true
  validates :difficulty, :respawn_seconds, numericality: {greater_than: 0}
end


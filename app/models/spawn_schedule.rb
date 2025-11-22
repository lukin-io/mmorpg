# frozen_string_literal: true

class SpawnSchedule < ApplicationRecord
  belongs_to :configured_by, class_name: "User"

  scope :active, -> { where(active: true) }

  validates :region_key, :monster_key, presence: true
  validates :respawn_seconds, numericality: {greater_than: 0}
end

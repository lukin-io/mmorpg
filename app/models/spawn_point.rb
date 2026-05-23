# frozen_string_literal: true

# Defines city spawn coordinates plus respawn timers within a zone.
class SpawnPoint < ApplicationRecord
  belongs_to :zone

  scope :default_entries, -> { where(default_entry: true) }

  validates :x, :y, numericality: {only_integer: true}
  validates :respawn_seconds, numericality: {greater_than: 0}
end

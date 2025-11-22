# frozen_string_literal: true

# Defines faction/city spawn coordinates plus respawn timers within a zone.
class SpawnPoint < ApplicationRecord
  belongs_to :zone

  scope :default_entries, -> { where(default_entry: true) }
  scope :matching_faction, ->(key) { key.present? ? where(faction_key: key) : all }

  validates :x, :y, numericality: {only_integer: true}
  validates :faction_key, presence: true
  validates :respawn_seconds, numericality: {greater_than: 0}
end


# frozen_string_literal: true

# Defines source-backed entry coordinates within a zone.
class SpawnPoint < ApplicationRecord
  belongs_to :zone

  scope :default_entries, -> { where(default_entry: true) }

  validates :x, :y, numericality: {only_integer: true}
end
